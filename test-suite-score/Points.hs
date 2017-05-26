{-# LANGUAGE RecordWildCards #-}
module Points (tallyUnits, taskPoints) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit as HU ((@?=), testCase)

import qualified Flight.Score as FS
import Flight.Score
    ( LaunchToSssPoints(..)
    , MinimumDistancePoints(..)
    , SecondsPerPoint(..)
    , JumpedTheGun(..)
    , EarlyStartPenalty(..)
    , TaskPenalties(..)
    , TaskPointParts(..)
    , TaskPoints(..)
    , zeroPenalties
    , zeroPoints
    )

import TestNewtypes

tallyUnits :: TestTree
tallyUnits = testGroup "Tally task points, with and without penalties"
    [ HU.testCase "No penalties, no points = zero task points" $
        FS.taskPoints zeroPenalties zeroPoints @?= TaskPoints 0

    , HU.testCase "No penalties = sum of distance, leading, time & arrival points" $
        FS.taskPoints
            zeroPenalties
            TaskPointParts { distance = 1, leading = 1, time = 1, arrival = 1 }
            @?= TaskPoints 4

    , HU.testCase "Early start PG = distance to start points only" $
        FS.taskPoints
            zeroPenalties { earlyStart = Just (EarlyStartPg $ LaunchToSssPoints 1) }
            TaskPointParts { distance = 10, leading = 10, time = 10, arrival = 10 }
            @?= TaskPoints 1

    , HU.testCase "Way too early start HG = minimum distance points only" $
        FS.taskPoints
            zeroPenalties { earlyStart = Just (EarlyStartHgMax $ MinimumDistancePoints 1) }
            TaskPointParts { distance = 10, leading = 10, time = 10, arrival = 10 }
            @?= TaskPoints 1

    , HU.testCase "Somewhat early start HG = full points minus jump the gun penalty" $
        FS.taskPoints
            zeroPenalties { earlyStart = Just (EarlyStartHg (SecondsPerPoint 1) (JumpedTheGun 1)) }
            TaskPointParts { distance = 10, leading = 10, time = 10, arrival = 10 }
            @?= TaskPoints 39
    ]

correct :: TaskPenalties -> TaskPointParts -> TaskPoints -> Bool
correct penalties TaskPointParts{..} (TaskPoints pts)
    | penalties == zeroPenalties =
        pts == distance + leading + time + arrival
    | otherwise =
        True

taskPoints :: PtTest -> Bool
taskPoints (PtTest (penalties, parts)) =
    correct penalties parts $ FS.taskPoints penalties parts
