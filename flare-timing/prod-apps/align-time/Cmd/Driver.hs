{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE QuasiQuotes #-}

{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE PartialTypeSignatures #-}

{-# OPTIONS_GHC -fplugin Data.UnitsOfMeasure.Plugin #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Cmd.Driver (driverMain) where

import System.Environment (getProgName)
import System.Console.CmdArgs.Implicit (cmdArgs)
import Prelude hiding (span)
import Formatting ((%), fprint)
import Formatting.Clock (timeSpecs)
import System.Clock (getTime, Clock(Monotonic))
import Data.Time.Clock (UTCTime, diffUTCTime)
import Data.Maybe (catMaybes)
import Control.Monad (mapM_, when, zipWithM_)
import Control.Monad.Except (ExceptT, runExceptT)
import Data.UnitsOfMeasure ((/:), u, convert, toRational')
import Data.UnitsOfMeasure.Internal (Quantity(..))
import System.Directory (createDirectoryIfMissing)
import System.FilePath ((</>), takeFileName)
import Flight.Cmd.Paths (checkPaths)
import Flight.Cmd.Options (CmdOptions(..), ProgramName(..), mkOptions)
import Cmd.Options (description)
import Cmd.Inputs (readTags)
import Cmd.Outputs (writeTimeRowsToCsv)

import Flight.Comp
    ( AlignDir(..)
    , CompInputFile(..)
    , TagZoneFile(..)
    , AlignTimeFile(..)
    , CompSettings(..)
    , Pilot(..)
    , Task(..)
    , TrackFileFail
    , SpeedSection
    , compToCross
    , crossToTag
    , compFileToCompDir
    , alignPath
    , findCompInput
    )
import Flight.TrackLog (IxTask(..))
import Flight.Units ()
import Flight.Mask
    (TaskZone, SigMasking, Ticked, RaceSections(..)
    , checkTracks, groupByLeg, distancesToGoal, zoneToCylinder
    )
import Flight.Track.Cross (Fix(..))
import Flight.Zone (Bearing(..))
import Flight.Zone.Raw (RawZone)
import Flight.Track.Time (TimeRow(..))
import Flight.Track.Tag (Tagging(..), TrackTime(..))
import Flight.Kml (MarkedFixes(..))
import Data.Number.RoundingFunctions (dpRound)
import Flight.Distance (TaskDistance(..))
import Flight.Task (SpanLatLng, CircumSample, AngleCut(..))
import Flight.PointToPoint.Double
    (distanceHaversine, distancePointToPoint, costSegment)
import Flight.Cylinder.Double (circumSample)

type Leg = Int

unTaskDistance :: (Real a, Fractional a) => TaskDistance a -> a
unTaskDistance (TaskDistance d) =
    fromRational $ dpRound 3 dKm
    where 
        MkQuantity dKm = toRational' $ convert d :: Quantity _ [u| km |]

headers :: [String]
headers = ["leg", "time", "lat", "lng", "tick", "distance"]

driverMain :: IO ()
driverMain = do
    name <- getProgName
    options <- cmdArgs $ mkOptions (ProgramName name) description Nothing
    err <- checkPaths options
    maybe (drive options) putStrLn err

drive :: CmdOptions -> IO ()
drive o = do
    -- SEE: http://chrisdone.com/posts/measuring-duration-in-haskell
    start <- getTime Monotonic
    files <- findCompInput o
    if null files then putStrLn "Couldn't find input files."
                  else mapM_ (go o) files
    end <- getTime Monotonic
    fprint ("Aligning times completed in " % timeSpecs % "\n") start end

go :: CmdOptions -> CompInputFile -> IO ()
go CmdOptions{..} compFile@(CompInputFile compPath) = do
    let tagFile@(TagZoneFile tagPath) = crossToTag . compToCross $ compFile
    putStrLn $ "Reading competition from '" ++ takeFileName compPath ++ "'"
    putStrLn $ "Reading zone tags from '" ++ takeFileName tagPath ++ "'"

    tags <- runExceptT $ readTags tagFile
    case tags of
        Left msg ->
            print msg

        Right tags' ->
            writeTime
                (IxTask <$> task)
                (Pilot <$> pilot)
                (CompInputFile compPath)
                (checkAll $ zonesFirst <$> timing tags')

writeTime :: [IxTask]
          -> [Pilot]
          -> CompInputFile
          -> (CompInputFile
              -> [IxTask]
              -> [Pilot]
              -> ExceptT
                  String IO [[Either (Pilot, t) (Pilot, Pilot -> [TimeRow])]])
          -> IO ()
writeTime selectTasks selectPilots compFile f = do
    checks <- runExceptT $ f compFile selectTasks selectPilots

    case checks of
        Left msg -> print msg
        Right xs -> do
            let ys :: [[(Pilot, [TimeRow])]] =
                    (fmap . fmap)
                        (\case
                            Left (p, _) -> (p, [])
                            Right (p, g) -> (p, g p))
                        xs

            _ <- zipWithM_
                (\ n zs ->
                    when (includeTask selectTasks $ IxTask n) $
                        mapM_ (writePilotTimes compFile n) zs)
                [1 .. ]
                ys

            return ()

checkAll :: [[Maybe UTCTime]]
         -> CompInputFile
         -> [IxTask]
         -> [Pilot]
         -> ExceptT
             String
             IO
             [
                 [Either
                     (Pilot, TrackFileFail)
                     (Pilot, Pilot -> [TimeRow])
                 ]
             ]
checkAll ts = checkTracks $ \CompSettings{tasks} -> group ts tasks

includeTask :: [IxTask] -> IxTask -> Bool
includeTask tasks = if null tasks then const True else (`elem` tasks)

writePilotTimes :: CompInputFile -> Int -> (Pilot, [TimeRow]) -> IO ()
writePilotTimes compFile iTask (pilot, rows) = do
    _ <- createDirectoryIfMissing True dOut
    _ <- writeTimeRowsToCsv (AlignTimeFile $ dOut </> f) headers rows
    return ()
    where
        dir = compFileToCompDir compFile
        (AlignDir dOut, AlignTimeFile f) = alignPath dir iTask pilot

mkTimeRows :: Maybe UTCTime
           -> Leg
           -> Maybe [(Maybe Fix, Maybe (TaskDistance Double))]
           -> [TimeRow]
mkTimeRows Nothing _ _ = []
mkTimeRows _ _ Nothing = []
mkTimeRows t0 leg (Just xs) = catMaybes $ mkTimeRow t0 leg <$> xs

mkTimeRow :: Maybe UTCTime
          -> Int
          -> (Maybe Fix, Maybe (TaskDistance Double))
          -> Maybe TimeRow
mkTimeRow Nothing _ _ = Nothing
mkTimeRow _ _ (Nothing, _) = Nothing
mkTimeRow _ _ (_, Nothing) = Nothing
mkTimeRow (Just t0) leg (Just Fix{time, lat, lng}, Just d) =
    Just
        TimeRow
            { leg = leg
            , time = time
            , tick = realToFrac $ diffUTCTime time t0
            , lat = lat
            , lng = lng
            , distance = unTaskDistance d
            }

group :: [[Maybe UTCTime]] -> SigMasking (Pilot -> [TimeRow])
group ts tasks iTask fs =
    \ _ ->
        concat $ zipWith3 (legDistances ts tasks iTask)
            [1 .. ]
            speedLegs
            ys
    where
        speedLegs = speedSection <$> tasks

        ys :: [MarkedFixes]
        ys = groupByLeg span zoneToCyl tasks iTask fs

legDistances :: [[Maybe UTCTime]]
             -> [Task]
             -> IxTask
             -> Leg
             -> SpeedSection
             -> MarkedFixes
             -> [TimeRow]
legDistances ts tasks iTask leg speedSection xs =
    case speedSection of
        Nothing ->
            []

        Just (start, end) ->
            if leg' < start || leg' > end then [] else
            mkTimeRows t0 leg xs'
            where
                ticked :: Ticked
                ticked =
                    RaceSections
                        []
                        -- TODO: Read ticked for align-times.
                        (replicate (leg - fromInteger start) 0)
                        []

                xs' = distancesToGoal ticked span dpp cseg cs cut zoneToCyl tasks iTask xs
    where
        leg' = fromIntegral leg
        t0 = firstCrossing iTask speedSection ts
        dpp = distancePointToPoint
        cseg = costSegment span

firstCrossing :: IxTask -> SpeedSection -> [[Maybe UTCTime]] -> Maybe UTCTime

firstCrossing (IxTask n) Nothing ts =
    case drop (n - 1) ts of
        [] ->
            Nothing

        (tsOfTask : _) ->
            case tsOfTask of
                [] -> Nothing
                (t : _) -> t

firstCrossing (IxTask n) (Just (leg, _)) ts =
    case drop (n - 1) ts of
        [] ->
            Nothing

        (tsOfTask : _) ->
            case drop (fromInteger leg - 1) tsOfTask of
                [] -> Nothing
                (t : _) -> t

zoneToCyl :: RawZone -> TaskZone Double
zoneToCyl = zoneToCylinder

span :: SpanLatLng Double
span = distanceHaversine

cs :: CircumSample Double
cs = circumSample

cut :: AngleCut Double
cut =
    AngleCut
        { sweep = Bearing . MkQuantity $ pi
        , nextSweep = nextCut
        }

nextCut :: AngleCut Double -> AngleCut Double
nextCut x@AngleCut{sweep} =
    let (Bearing b) = sweep in x{sweep = Bearing $ b /: 2}
