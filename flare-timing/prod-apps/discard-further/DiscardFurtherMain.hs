{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

import Prelude hiding (last)
import Data.Maybe (fromMaybe)
import Data.List.NonEmpty (nonEmpty, last)
import System.Environment (getProgName)
import System.Console.CmdArgs.Implicit (cmdArgs)
import Formatting ((%), fprint)
import Formatting.Clock (timeSpecs)
import System.Clock (getTime, Clock(Monotonic))
import Control.Monad (join, mapM_)
import Control.Exception.Safe (catchIO)
import System.FilePath (takeFileName)

import Flight.Clip (FlyCut(..), FlyClipping(..))
import Flight.Cmd.Paths (LenientFile(..), checkPaths)
import Flight.Cmd.Options (ProgramName(..))
import Flight.Cmd.BatchOptions (CmdBatchOptions(..), mkOptions)
import Flight.Zone.MkZones (Zones(..))
import Flight.Zone.Raw (RawZone(..))
import qualified Flight.Comp as Cmp (openClose)
import Flight.Route (OptimalRoute(..))
import Flight.Comp
    ( FileType(CompInput)
    , CompInputFile(..)
    , TagZoneFile(..)
    , TaskLengthFile(..)
    , CompSettings(..)
    , Comp(..)
    , TaskStop(..)
    , Task(..)
    , PilotName(..)
    , Pilot(..)
    , TrackFileFail
    , IxTask(..)
    , StartEndDown(..)
    , StartEndDownMark
    , RoutesLookupTaskDistance(..)
    , FirstLead(..)
    , FirstStart(..)
    , LastArrival(..)
    , LastDown(..)
    , compToTaskLength
    , compToCross
    , crossToTag
    , findCompInput
    , speedSectionToLeg
    , ensureExt
    , pilotNamed
    )
import Flight.Track.Time (TimeToTick, glideRatio, altBonusTimeToTick, copyTimeToTick)
import Flight.Track.Mask (RaceTime(..), racing)
import Flight.Mask (checkTracks)
import Flight.Scribe
    ( readComp, readRoute, readTagging
    , readPilotAlignTimeWriteDiscardFurther
    , readPilotAlignTimeWritePegThenDiscard
    )
import Flight.Lookup.Route (routeLength)
import Flight.Lookup.Tag (TaskLeadingLookup(..), tagTaskLeading)
import DiscardFurtherOptions (description)

main :: IO ()
main = do
    name <- getProgName
    options <- cmdArgs $ mkOptions (ProgramName name) description Nothing

    let lf = LenientFile {coerceFile = ensureExt CompInput}
    err <- checkPaths lf options

    maybe (drive options) putStrLn err

drive :: CmdBatchOptions -> IO ()
drive o = do
    -- SEE: http://chrisdone.com/posts/measuring-duration-in-haskell
    start <- getTime Monotonic
    files <- findCompInput o
    if null files then putStrLn "Couldn't find any input files."
                  else mapM_ (go o) files
    end <- getTime Monotonic
    fprint ("Filtering times completed in " % timeSpecs % "\n") start end

go :: CmdBatchOptions -> CompInputFile -> IO ()
go CmdBatchOptions{..} compFile@(CompInputFile compPath) = do
    let lenFile@(TaskLengthFile lenPath) = compToTaskLength compFile
    let tagFile@(TagZoneFile tagPath) = crossToTag . compToCross $ compFile
    putStrLn $ "Reading competition from '" ++ takeFileName compPath ++ "'"
    putStrLn $ "Reading task length from '" ++ takeFileName lenPath ++ "'"
    putStrLn $ "Reading zone tags from '" ++ takeFileName tagPath ++ "'"

    compSettings <-
        catchIO
            (Just <$> readComp compFile)
            (const $ return Nothing)

    tagging <-
        catchIO
            (Just <$> readTagging tagFile)
            (const $ return Nothing)

    routes <-
        catchIO
            (Just <$> readRoute lenFile)
            (const $ return Nothing)

    case (compSettings, tagging, routes) of
        (Nothing, _, _) -> putStrLn "Couldn't read the comp settings."
        (_, Nothing, _) -> putStrLn "Couldn't read the taggings."
        (_, _, Nothing) -> putStrLn "Couldn't read the routes."
        (Just cs, Just _, Just _) ->
            filterTime
                cs
                (routeLength taskRoute taskRouteSpeedSubset stopRoute routes)
                (tagTaskLeading tagging)
                compFile
                (IxTask <$> task)
                (pilotNamed cs $ PilotName <$> pilot)
                checkAll

filterTime
    :: CompSettings k
    -> RoutesLookupTaskDistance
    -> TaskLeadingLookup
    -> CompInputFile
    -> [IxTask]
    -> [Pilot]
    -> (CompInputFile
        -> [IxTask]
        -> [Pilot]
        -> IO [[Either (Pilot, _) (Pilot, _)]])
    -> IO ()
filterTime
    CompSettings{comp = Comp{discipline = hgOrPg}, tasks}
    lengths
    (TaskLeadingLookup lookupTaskLeading)
    compFile selectTasks selectPilots f = do

    checks <-
        catchIO
            (Just <$> f compFile selectTasks selectPilots)
            (const $ return Nothing)

    case checks of
        Nothing -> putStrLn "Unable to read tracks for pilots."
        Just xs -> do
            let taskPilots :: [[Pilot]] =
                    (fmap . fmap)
                        (\case
                            Left (p, _) -> p
                            Right (p, _) -> p)
                        xs

            let iTasks = IxTask <$> [1 .. length taskPilots]

            let raceTs :: [Maybe StartEndDownMark] =
                    join <$>
                    [ ($ s) . ($ i) <$> lookupTaskLeading
                    | i <- iTasks
                    | s <- speedSection <$> tasks
                    ]

            let raceFirstLead :: [Maybe FirstLead] =
                    (fmap . fmap) (FirstLead . unStart) raceTs

            let raceFirstStart :: [Maybe FirstStart] =
                    (fmap . fmap) (FirstStart . unStart) raceTs

            let raceLastArrival :: [Maybe LastArrival] =
                    join
                    <$> (fmap . fmap) (fmap LastArrival . unEnd) raceTs

            let raceLastDown :: [Maybe LastDown] =
                    join
                    <$> (fmap . fmap) (fmap LastDown . unDown) raceTs

            let compRaceTimes :: [Maybe RaceTime] =
                    [ racing (Cmp.openClose ss zt) fl fs la ld
                    | ss <- speedSection <$> tasks
                    | zt <- zoneTimes <$> tasks
                    | fl <- raceFirstLead
                    | fs <- raceFirstStart
                    | la <- raceLastArrival
                    | ld <- raceLastDown
                    ]

            let raceTime =
                    [ do
                        rt@RaceTime{..} <- crt
                        return $
                            maybe
                                rt
                                (\stp ->
                                    uncut . clipToCut $
                                        FlyCut
                                            { cut = Just (openTask, min stp closeTask)
                                            , uncut = rt
                                            })
                                (retroactive <$> stopped task)

                    | crt <- compRaceTimes
                    | task <- tasks
                    ]

            sequence_
                [
                    mapM_
                        (readPilotAlignTimeWriteDiscardFurther
                            copyTimeToTick
                            id
                            lengths
                            compFile
                            (includeTask selectTasks)
                            n
                            toLeg
                            rt)
                        pilots
                | n <- (IxTask <$> [1 .. ])
                | toLeg <- speedSectionToLeg . speedSection <$> tasks
                | rt <- raceTime
                | pilots <- taskPilots
                ]

            let altBonusesOnTime :: [TimeToTick] =
                    [
                        fromMaybe copyTimeToTick $ do
                            _ <- stopped
                            zs' <- nonEmpty zs
                            let RawZone{alt} = last zs'
                            altBonusTimeToTick (glideRatio hgOrPg) <$> alt

                    | Task{stopped, zones = Zones{raw = zs}} <- tasks
                    ]

            sequence_
                [
                    mapM_
                        (readPilotAlignTimeWritePegThenDiscard
                            timeToTick
                            id
                            lengths
                            compFile
                            (includeTask selectTasks)
                            n
                            toLeg
                            rt)
                        pilots
                | n <- (IxTask <$> [1 .. ])
                | toLeg <- speedSectionToLeg . speedSection <$> tasks
                | rt <- raceTime
                | pilots <- taskPilots
                | timeToTick <- altBonusesOnTime
                ]

checkAll
    :: CompInputFile
    -> [IxTask]
    -> [Pilot]
    -> IO [[Either (Pilot, TrackFileFail) (Pilot, ())]]
checkAll = checkTracks $ \CompSettings{tasks} -> (\ _ _ _ -> ()) tasks

includeTask :: [IxTask] -> IxTask -> Bool
includeTask tasks = if null tasks then const True else (`elem` tasks)
