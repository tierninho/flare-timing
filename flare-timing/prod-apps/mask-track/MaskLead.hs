﻿{-# OPTIONS_GHC -fplugin Data.UnitsOfMeasure.Plugin #-}
module MaskLead (maskLead) where

import Data.Maybe (catMaybes)
import Data.UnitsOfMeasure (u, convert, toRational')
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.Comp
    ( Pilot(..)
    , Task(..)
    , TaskRouteDistance(..)
    , MadeGoal(..)
    , LandedOut(..)
    )
import Flight.Distance
    (QTaskDistance, TaskDistance(..), unTaskDistanceAsKm)
import Flight.Comp.Distance (compDistance)
import Flight.Track.Time (LeadTick)
import qualified Flight.Track.Time as Time (TickRow(..))
import Flight.Track.Lead (compLeading)
import Flight.Track.Mask (MaskingLead(..), RaceTime(..))
import Flight.Score (BestTime(..), MinimumDistance(..), LengthOfSs(..), areaToCoef)

maskLead
    :: (MinimumDistance (Quantity Double [u| km |]))
    -> [Task k]
    -> [Maybe RaceTime]
    -> [Maybe TaskRouteDistance]
    -> [[Pilot]]
    -> [[Pilot]]
    -> [Maybe (BestTime (Quantity Double [u| h |]))]
    -> [[Maybe (Pilot, Time.TickRow)]]
    -> [[(Pilot, [Time.TickRow])]]
    -> ( [Maybe (QTaskDistance Double [u| m |])]
       , [[Maybe (Pilot, Maybe LeadTick)]]
       , MaskingLead
       )
maskLead
    free
    tasks
    raceTime
    lsTask
    psArriving
    psLandingOut
    gsBestTime
    rows
    rowsLeadingStep =
    (dsBest, rowTicks,) $
    MaskingLead
        { raceTime = raceTime
        , sumDistance = dsSum
        , leadAreaToCoef = lcAreaToCoef
        , leadCoefMin = lcMin
        , leadRank = lead
        }
    where
        lsWholeTask = (fmap . fmap) wholeTaskDistance lsTask
        lsSpeedSubset = (fmap . fmap) speedSubsetDistance lsTask
        (lcMin, lead) = compLeading rowsLeadingStep lsSpeedSubset tasks

        lcAreaToCoef =
                [
                    areaToCoef
                    . LengthOfSs
                    . (\(TaskDistance d) -> convert . toRational' $ d)
                    <$> ssLen
                | ssLen <- lsSpeedSubset
                ]

        (dsSumArriving, dsSumLandingOut, dsBest, rowTicks) =
                compDistance
                    free
                    lsWholeTask
                    (MadeGoal <$> psArriving)
                    (LandedOut <$> psLandingOut)
                    gsBestTime
                    rows

        -- NOTE: This is the sum of distance over minimum distance.
        dsSum =
                [
                    (fmap $ TaskDistance . MkQuantity)
                    . (\case 0 -> Nothing; x -> Just x)
                    . sum
                    . fmap unTaskDistanceAsKm
                    . catMaybes
                    $ [aSum, lSum]
                | aSum <- dsSumArriving
                | lSum <- dsSumLandingOut
                ]

