{-# OPTIONS_GHC -fno-warn-unused-binds #-}

{-|
Module      : Flight.Score
Copyright   : (c) Block Scope Limited 2017
License     : BSD3
Maintainer  : phil.dejoux@blockscope.com
Stability   : experimental

Provides GAP scoring for hang gliding and paragliding competitons.
-}
module Flight.Score
    ( -- * Nominals
      NominalLaunch(..)
    , NominalTime(..)
    , NominalDistance(..)
    , NominalGoal(..)
    -- * Units
    , Seconds
    , Metres
    -- * Ratio
    , isNormal
    , isFoldNormal
    -- * Validity
    , LaunchValidity(..)
    , TimeValidity(..)
    , DistanceValidity(..)
    , TaskValidity(..)
    , launchValidity
    , distanceValidity
    , timeValidity
    , taskValidity
    -- * Weighting
    , GoalRatio(..)
    , DistanceRatio(..)
    , DistanceWeight(..)
    , LeadingWeight(..)
    , ArrivalWeight(..)
    , TimeWeight(..)
    , Lw(..)
    , Aw(..)
    , distanceWeight
    , leadingWeight
    , arrivalWeight
    , timeWeight
    -- * Fractional allotment of arrival points
    , PilotsAtEss(..)
    , PositionAtEss(..)
    , ArrivalFraction(..)
    , arrivalFraction
    -- * Fractional allotment of time points
    , BestTime(..)
    , PilotTime(..)
    , SpeedFraction(..)
    , speedFraction
    -- * Fractional allotment of linear distance points
    , BestDistance(..)
    , PilotDistance(..)
    , LinearFraction(..)
    , linearFraction
    -- * Fractional allotment of difficulty distance points
    , LookaheadChunks(..)
    , ChunkedDistance(..)
    , lookaheadChunks
    , toChunk
    , DifficultyFraction(..)
    , difficultyFraction
    -- * Fractional allotment of leading points 
    , TaskTime(..)
    , DistanceToEss(..)
    , LcTrack(..)
    , TaskDeadline(..)
    , LengthOfSs(..)
    , LeadingCoefficient(..)
    , LeadingFraction(..)
    , leadingFractions
    , leadingCoefficient
    , madeGoal
    , cleanTrack
    -- * Tallying points 
    , LaunchToSssPoints(..)
    , MinimumDistancePoints(..)
    , SecondsPerPoint(..)
    , JumpedTheGun(..)
    , EarlyStartPenalty(..)
    , NoGoalPenalty(..)
    , TaskPenalties(..)
    , TaskPointParts(..)
    , TaskPoints(..)
    , zeroPenalties
    , zeroPoints
    , taskPoints
    ) where

import Flight.Ratio
import Flight.Allot
import Flight.Leading
import Flight.Validity
import Flight.Weighting
import Flight.Points

type DistancePoint = Rational
type SpeedPoint = Rational
type DeparturePoint = Rational
type ArrivalPoint = Rational

data FixDistance = FixDistance Seconds Metres
data PointsAllocation =
    PointsAllocation { distance :: Rational
                     , speed :: Rational
                     , departure :: Rational
                     , arrival :: Rational
                     }

distancePoints :: [Metres] -> [DistancePoint]
distancePoints = undefined

speedPoints :: [Seconds] -> [SpeedPoint]
speedPoints = undefined

departurePoints :: [FixDistance] -> [DeparturePoint]
departurePoints = undefined

arrivalPoints :: Int -> [ArrivalPoint]
arrivalPoints = undefined

allocatePoints :: Rational -> PointsAllocation
allocatePoints = undefined
