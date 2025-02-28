module Points (tallyUnits, taskPointsHg, taskPointsPg) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit as HU ((@?=), testCase)
import Data.Ratio ((%))

import qualified Flight.Score as FS
import Flight.Score
    ( LaunchToSssPoints(..)
    , MinimumDistancePoints(..)
    , SecondsPerPoint(..)
    , JumpedTheGun(..)
    , Hg
    , Pg
    , Penalty(..)
    , LinearPoints(..)
    , DifficultyPoints(..)
    , DistancePoints(..)
    , LeadingPoints(..)
    , ArrivalPoints(..)
    , TimePoints(..)
    , TaskPoints(..)
    , Points(..)
    , zeroPoints
    )

import TestNewtypes

tallyUnits :: TestTree
tallyUnits = testGroup "Tally task points, with and without penalties"
    [ HU.testCase "No penalties, no points = zero task points" $
        FS.taskPoints (Nothing :: Maybe (Penalty Hg)) zeroPoints @?= TaskPoints 0

    , HU.testCase "No penalties = sum of distance, leading, time & arrival points" $
        FS.taskPoints
            Nothing
            Points
                { reach = LinearPoints 1
                , effort = DifficultyPoints 1
                , distance = DistancePoints 2
                , leading = LeadingPoints 1
                , arrival = ArrivalPoints 1
                , time = TimePoints 1
                }
            @?= TaskPoints 5

    , HU.testCase "Early start PG = distance to start points only" $
        FS.taskPoints
            (Just (Early $ LaunchToSssPoints 1))
            Points
                { reach = LinearPoints 10
                , effort = DifficultyPoints 10
                , distance = DistancePoints 20
                , leading = LeadingPoints 10
                , arrival = ArrivalPoints 10
                , time = TimePoints 10
                }
            @?= TaskPoints 1

    , HU.testCase "Way too early start HG = minimum distance points only" $
        FS.taskPoints
            (Just (JumpedTooEarly $ MinimumDistancePoints 1))
            Points
                { reach = LinearPoints 10
                , effort = DifficultyPoints 10
                , distance = DistancePoints 20
                , leading = LeadingPoints 10
                , arrival = ArrivalPoints 10
                , time = TimePoints 10
                }
            @?= TaskPoints 1

    , HU.testCase "Somewhat early start HG = full points minus jump the gun penalty" $
        FS.taskPoints
            (Just (Jumped (SecondsPerPoint 1) (JumpedTheGun 1)))
            Points
                { reach = LinearPoints 10
                , effort = DifficultyPoints 10
                , distance = DistancePoints 20
                , leading = LeadingPoints 10
                , arrival = ArrivalPoints 10
                , time = TimePoints 10
                }
            @?= TaskPoints 49
    ]

correct :: forall a. Maybe (Penalty a) -> Points -> TaskPoints -> Bool

correct
    Nothing
    Points
        { reach = LinearPoints r
        , effort = DifficultyPoints e
        , leading = LeadingPoints l
        , arrival = ArrivalPoints a
        , time = TimePoints t
        }
    pts =
    pts == TaskPoints (r + e + l + t + a)

correct
    (Just (JumpedTooEarly (MinimumDistancePoints md)))
    _
    pts =
    pts == TaskPoints md

correct
    (Just (Jumped (SecondsPerPoint spp) (JumpedTheGun jtg)))
    Points
        { reach = LinearPoints r
        , effort = DifficultyPoints e
        , leading = LeadingPoints l
        , arrival = ArrivalPoints a
        , time = TimePoints t
        }
    pts =
    pts == TaskPoints (max 0 x)
    where
        x = (r + e + l + t + a) - jtg / spp

correct
    (Just (JumpedNoGoal (SecondsPerPoint spp) (JumpedTheGun jtg)))
    Points
        { reach = LinearPoints r
        , effort = DifficultyPoints e
        , leading = LeadingPoints l
        , arrival = ArrivalPoints a
        , time = TimePoints t
        }
    pts =
    pts == TaskPoints (max 0 x)
    where
        x = (r + e + l + (8 % 10) * (t + a)) - jtg / spp

correct
    (Just NoGoalHg)
    Points
        { reach = LinearPoints r
        , effort = DifficultyPoints e
        , leading = LeadingPoints l
        , arrival = ArrivalPoints a
        , time = TimePoints t
        }
    pts =
    pts == TaskPoints (r + e + l + (8 % 10) * (t + a))

correct (Just (Early (LaunchToSssPoints lts))) Points{..} (TaskPoints pts) =
    pts == lts

correct
    (Just NoGoalPg)
    Points
        { reach = LinearPoints r
        , effort = DifficultyPoints e
        , leading = LeadingPoints l
        }
    pts =
    pts == TaskPoints (r + e + l)

taskPointsHg :: PtTest Hg -> Bool
taskPointsHg (PtTest (penalty, parts)) =
    correct penalty parts $ FS.taskPoints penalty parts

taskPointsPg :: PtTest Pg -> Bool
taskPointsPg (PtTest (penalty, parts)) =
    correct penalty parts $ FS.taskPoints penalty parts
