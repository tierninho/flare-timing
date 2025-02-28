module Flight.Lookup
    ( flyingTimeRange
    , scoredTimeRange
    , arrivalRank
    , pilotTime
    , pilotEssTime
    , ticked
    , compRoutes
    , compRaceTimes
    ) where

import Data.Time.Clock (UTCTime)
import Data.Maybe (fromMaybe)
import Control.Monad (join)
import Data.UnitsOfMeasure (u)
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.Clip (FlyingSection)
import Flight.Kml (MarkedFixes(..))
import Flight.Zone.SpeedSection (SpeedSection)
import Flight.Comp
    ( IxTask(..)
    , Task(..)
    , Pilot(..)
    , RoutesLookupTaskDistance(..)
    , TaskRouteDistance
    , StartGate
    , FirstStart(..)
    , FirstLead(..)
    , LastArrival(..)
    , LastDown(..)
    , StartEndDown(..)
    , StartEndDownMark
    )
import qualified Flight.Comp as Cmp (openClose)
import Flight.Score (ArrivalPlacing(..), PilotTime(..), JumpedTheGun(..))
import Flight.Track.Mask (RaceTime(..), racing)
import Flight.Track.Cross (TrackFlyingSection(..))
import Flight.Track.Stop (TrackScoredSection(..))
import Flight.Track.Time (ZoneIdx)
import Flight.Mask (RaceSections(..))
import qualified Flight.Track.Speed as Speed (pilotTime, pilotEssTime)
import Flight.Lookup.Cross (FlyingLookup(..))
import Flight.Lookup.Stop (ScoredLookup(..))
import Flight.Lookup.Tag
    ( ArrivalRankLookup(..) , TaskLeadingLookup(..)
    , TimeLookup(..), TickLookup(..)
    )

flyingTimeRange :: FlyingLookup -> UTCTime -> IxTask -> Pilot -> FlyingSection UTCTime
flyingTimeRange (FlyingLookup get) mark0 iTask p =
    fromMaybe
        (Just (mark0, mark0))
        (fmap flyingTimes . (\f -> f iTask p) =<< get)

scoredTimeRange :: ScoredLookup -> UTCTime -> IxTask -> Pilot -> FlyingSection UTCTime
scoredTimeRange (ScoredLookup get) mark0 iTask p =
    fromMaybe
        (Just (mark0, mark0))
        (fmap scoredTimes . (\f -> f iTask p) =<< get)

arrivalRank
    :: ArrivalRankLookup
    -> MarkedFixes
    -> IxTask
    -> SpeedSection
    -> Pilot
    -> Maybe ArrivalPlacing
arrivalRank (ArrivalRankLookup get) mf iTask speedSection p =
    ArrivalPlacing . toInteger
    <$> ((\f -> f iTask speedSection p mf) =<< get)

pilotTime
    :: TimeLookup
    -> MarkedFixes
    -> IxTask
    -> [StartGate]
    -> SpeedSection
    -> Pilot
    -> Maybe (PilotTime (Quantity Double [u| h |]))
pilotTime (TimeLookup get) mf iTask startGates speedSection p =
    Speed.pilotTime startGates
    =<< ((\f -> f iTask speedSection p mf) =<< get)

pilotEssTime
    :: TimeLookup
    -> MarkedFixes
    -> IxTask
    -> [StartGate]
    -> SpeedSection
    -> Pilot
    -> (Maybe (JumpedTheGun (Quantity Double [u| s |])), Maybe UTCTime)
pilotEssTime (TimeLookup get) mf iTask startGates speedSection p =
    maybe
        (Nothing, Nothing)
        (Speed.pilotEssTime startGates)
        ((\f -> f iTask speedSection p mf) =<< get)

ticked
    :: TickLookup
    -> MarkedFixes
    -> IxTask
    -> SpeedSection
    -> Pilot
    -> RaceSections ZoneIdx
ticked (TickLookup get) mf iTask speedSection p =
    fromMaybe
        (RaceSections [] [] [])
        ((\f -> f iTask speedSection p mf) =<< get)

compRoutes
    :: RoutesLookupTaskDistance
    -> [IxTask]
    -> [Maybe TaskRouteDistance]
compRoutes (RoutesLookupTaskDistance get) iTasks =
    (\i -> ((\g -> g i) =<< get)) <$> iTasks

compTimes :: TaskLeadingLookup -> [IxTask] -> [Task k] -> [Maybe StartEndDownMark]
compTimes (TaskLeadingLookup get) iTasks tasks =
    join <$>
    [ ($ s) . ($ i) <$> get
    | i <- iTasks
    | s <- speedSection <$> tasks
    ]

compRaceTimes :: TaskLeadingLookup -> [IxTask] -> [Task k] -> [Maybe RaceTime]
compRaceTimes getTaskLeading iTasks tasks =
    [ racing (Cmp.openClose ss zt) fl fs la ld
    | ss <- speedSection <$> tasks
    | zt <- zoneTimes <$> tasks
    | fl <- raceFirstLead
    | fs <- raceFirstStart
    | la <- raceLastArrival
    | ld <- raceLastDown
    ]
    where
        xs :: [Maybe StartEndDownMark] =
                compTimes getTaskLeading iTasks tasks

        raceFirstLead :: [Maybe FirstLead] =
                (fmap . fmap) (FirstLead . unStart) xs

        raceFirstStart :: [Maybe FirstStart] =
                (fmap . fmap) (FirstStart . unStart) xs

        raceLastArrival :: [Maybe LastArrival] =
                join
                <$> (fmap . fmap) (fmap LastArrival . unEnd) xs

        raceLastDown :: [Maybe LastDown] =
                join
                <$> (fmap . fmap) (fmap LastDown . unDown) xs
