module TaskValidity
    ( taskValidityUnits
    , taskValidity
    ) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit as HU ((@?=), testCase)
import Data.Ratio ((%))

import qualified Flight.Score as FS
import Flight.Score
    ( LaunchValidity(..)
    , TimeValidity(..)
    , DistanceValidity(..)
    , TaskValidity(..)
    , isNormal
    )
import TestNewtypes

taskValidityUnits :: TestTree
taskValidityUnits = testGroup "Task validity unit tests"
    [ HU.testCase "1 launch validity, 1 time validity, 1 distance validity = 1 task validity" $
        FS.taskValidity
            (LaunchValidity (1 % 1))
            (DistanceValidity (1 % 1))
            (TimeValidity (1 % 1))
            @?= TaskValidity (1 % 1)

    , HU.testCase "0 launch validity, 1 time validity, 1 distance validity = 0 task validity" $
        FS.taskValidity
            (LaunchValidity (0 % 1))
            (DistanceValidity (1 % 1))
            (TimeValidity (1 % 1))
            @?= TaskValidity (0 % 1)

    , HU.testCase "1 launch validity, 0 time validity, 1 distance validity = 0 task validity" $
        FS.taskValidity
            (LaunchValidity (1 % 1))
            (DistanceValidity (1 % 1))
            (TimeValidity (0 % 1))
            @?= TaskValidity (0 % 1)

    , HU.testCase "1 launch validity, 1 time validity, 0 distance validity = 0 task validity" $
        FS.taskValidity
            (LaunchValidity (1 % 1))
            (DistanceValidity (0 % 1))
            (TimeValidity (1 % 1))
            @?= TaskValidity (0 % 1)
    ]

taskValidity :: TvTest -> Bool
taskValidity (TvTest (lv, dv, tv)) =
    (\(TaskValidity v) -> isNormal v)
    $ FS.taskValidity lv dv tv
