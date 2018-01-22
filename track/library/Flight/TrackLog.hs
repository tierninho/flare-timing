{-# LANGUAGE TupleSections #-}
{-# LANGUAGE PartialTypeSignatures #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE LambdaCase #-}

{-|
Module      : Flight.TrackLog
Copyright   : (c) Block Scope Limited 2017
License     : BSD3
Maintainer  : phil.dejoux@blockscope.com
Stability   : experimental

Competition pilot tracks logs.
-}
module Flight.TrackLog
    ( pilotTracks
    , filterPilots
    , filterTasks
    , makeAbsolute
    ) where

import Data.Ratio ((%))
import Data.Time.Clock (UTCTime(..), diffUTCTime, secondsToDiffTime)
import Data.Time.Calendar
import Data.Bifunctor (bimap)
import Data.Maybe (catMaybes, listToMaybe)
import Control.Monad.Except (ExceptT(..), runExceptT, lift)
import System.Directory (doesFileExist, doesDirectoryExist)
import System.FilePath
    ( FilePath
    , (</>)
    , takeDirectory
    , normalise
    , splitDirectories
    , joinPath
    , takeExtension
    )

import qualified Flight.Kml as K
    -- (MarkedFixes(..), Fix(..), LLA(..), parse)
import qualified Flight.Igc as I (parse)
import Flight.Igc
import Flight.Comp
    ( Pilot(..)
    , PilotTrackLogFile(..)
    , TrackLogFile(..)
    , TrackFileFail(..)
    , TaskFolder(..)
    , IxTask(..)
    )

ixTasks :: [IxTask]
ixTasks = IxTask <$> [ 1 .. ]

pilotTrack :: (K.MarkedFixes -> a)
           -> PilotTrackLogFile
           -> ExceptT
               (Pilot, TrackFileFail)
               IO
               (Pilot, a)
pilotTrack _ (PilotTrackLogFile p Nothing) =
    ExceptT . return $ Left (p, TrackLogFileNotSet)
pilotTrack f (PilotTrackLogFile p (Just (TrackLogFile file))) = do
    let folder = takeDirectory file
    dde <- lift $ doesDirectoryExist folder
    x <- lift $
            if not dde
                then
                    return . Left $ TaskFolderExistsNot folder
                else do
                    dfe <- doesFileExist file
                    if not dfe
                        then return . Left $ TrackLogFileExistsNot file
                        else do
                            contents <- readFile file

                            kml :: Either String K.MarkedFixes
                                <- case takeExtension file of
                                      ".kml" ->
                                          K.parse contents

                                      ".igc" ->
                                          case I.parse contents of
                                            Left _ ->
                                                return . Left
                                                $ "Can't parse IGC: " ++ file

                                            Right xs ->
                                                return . Right $ igcMarkedFixes xs

                                      _ ->
                                          K.parse contents

                            return $ bimap TrackLogFileNotRead f kml

    ExceptT . return . bimap (p,) (p,) $ x

taskPilotTracks :: (IxTask -> K.MarkedFixes -> a)
                -> [ (IxTask, [ PilotTrackLogFile ]) ]
                -> IO
                    [[ Either
                        (Pilot, TrackFileFail)
                        (Pilot, a)
                    ]]
taskPilotTracks _ [] =
    return []
taskPilotTracks f xs =
    sequence $ (\(i, ts) ->
        sequence $ (runExceptT . pilotTrack (f i)) <$> ts)
        <$> xs

pilotTracks :: (IxTask -> K.MarkedFixes -> a)
            -> [[ PilotTrackLogFile ]]
            -> IO
                [[ Either
                    (Pilot, TrackFileFail)
                    (Pilot, a)
                ]]
pilotTracks _ [] = return []
pilotTracks f tasks =
    taskPilotTracks f (zip ixTasks tasks) 

filterPilots :: [ Pilot ]
             -> [[ PilotTrackLogFile ]]
             -> [[ PilotTrackLogFile ]]

filterPilots [] xs = xs
filterPilots pilots xs =
    f <$> xs
    where
        f :: [ PilotTrackLogFile ] -> [ PilotTrackLogFile ]
        f ys =
            catMaybes
            $ (\x@(PilotTrackLogFile pilot _) ->
                if pilot `elem` pilots then Just x else Nothing)
            <$> ys

filterTasks :: [ IxTask ]
            -> [[ PilotTrackLogFile ]]
            -> [[ PilotTrackLogFile ]]

filterTasks [] xs = xs
filterTasks tasks xs =
    zipWith (\i ys ->
        if i `elem` tasks then ys else []) ixTasks xs

makeAbsolute :: FilePath
             -> TaskFolder
             -> PilotTrackLogFile
             -> PilotTrackLogFile
makeAbsolute _ _ x@(PilotTrackLogFile _ Nothing) = x
makeAbsolute
    dir
    (TaskFolder pathParts)
    (PilotTrackLogFile p (Just (TrackLogFile file))) =
    PilotTrackLogFile p (Just (TrackLogFile path))
    where
        parts :: [ FilePath ]
        parts = splitDirectories dir ++ pathParts

        path :: FilePath
        path = normalise $ joinPath parts </> file

nullMarkedFixes :: K.MarkedFixes
nullMarkedFixes = K.MarkedFixes (UTCTime (ModifiedJulianDay 0) 0) []

igcMarkedFixes :: [Flight.Igc.IgcRecord] -> K.MarkedFixes
igcMarkedFixes xs =
    maybe nullMarkedFixes (flip mark ys) date
    where
        date =
            listToMaybe
            . take 1
            . filter (\case HFDTE _ _ _ -> True; _ -> False)
            $ xs

        ys = filter (\case B{} -> True; _ -> False) xs

mark :: IgcRecord -> [IgcRecord] -> K.MarkedFixes
mark Ignore _ = nullMarkedFixes
mark B{} _ = nullMarkedFixes
mark (HFDTE dd mm yy) xs =
    unStamp Nothing ts
    where
        ys = catMaybes $ extract <$> xs
        ts = stamp (dd, mm, yy) <$> ys

extract :: IgcRecord -> Maybe (HMS, (Lat, Lng, AltBaro, Maybe AltGps))
extract Ignore = Nothing
extract HFDTE{} = Nothing
extract (B hms lat lng alt altGps) = Just (hms, (lat, lng, alt, altGps))

stamp :: (String, String, String) -> (HMS, a) -> (UTCTime, a)
stamp (dd, mm, yy) (HMS hr minute sec, a) =
    (utc, a)
    where
        -- TODO: Test with an IGC file from the 20th Century.
        y = read ("20" ++ yy) :: Integer
        m = read mm :: Int
        d = read dd :: Int
        hr' = read hr :: Integer
        minute' = read minute :: Integer
        sec' = read sec :: Integer
        utc =
            UTCTime
            (fromGregorian y m d)
            (secondsToDiffTime $ 60 * ((60 * hr') + minute') + sec')

unStamp
    :: Maybe UTCTime
    -> [(UTCTime, (Lat, Lng, AltBaro, Maybe AltGps))]
    -> K.MarkedFixes
unStamp _ [] = nullMarkedFixes
unStamp Nothing xs@((t, _) : _) = unStamp (Just t) xs
unStamp (Just mark0) xs =
    K.MarkedFixes
        { K.mark0 = mark0
        , K.fixes = toFix mark0 <$> xs 
        }

toFix :: UTCTime -> (UTCTime, (Lat, Lng, AltBaro, Maybe AltGps)) -> K.Fix
toFix mark0 (t, (lat, lng, altBaro, altGps)) =
    K.Fix
        { K.fixMark = K.Seconds . round $ t `diffUTCTime` mark0
        , K.fix =
            K.LLA
                { K.llaLat = readLat lat
                , K.llaLng = readLng lng
                , K.llaAltGps = readAltBaro $ altBaro
                }
        -- TODO: Which is Maybe GPS or BARO, KML vs IGC?
        , K.fixAltBaro = readAltGps <$> altGps
        }

readDegMin :: Degree -> Minute -> Rational
readDegMin d m =
    d' % 1 + (toRational m') / 60000
    where
        d' = read d :: Integer
        m' = read m :: Double

readLat :: Lat -> K.Latitude
readLat (LatN d m) = K.Latitude $ readDegMin d m
readLat (LatS d m) = K.Latitude . negate $ readDegMin d m

readLng :: Lng -> K.Longitude
readLng (LngE d m) = K.Longitude $ readDegMin d m
readLng (LngW d m) = K.Longitude . negate $ readDegMin d m

readAltBaro :: AltBaro -> K.Altitude
readAltBaro (AltBaro alt) =
    K.Altitude (read alt :: Integer)

readAltGps :: AltGps -> K.Altitude
readAltGps (AltGps alt) =
    K.Altitude (read alt :: Integer)
