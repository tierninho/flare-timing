module TimeValidity
    ( timeValidityUnits
    , scTimeValidity
    , qcTimeValidity
    ) where

import qualified Flight.Score as FS
import Flight.Score
    ( TimeValidity(..)
    , NominalTime(..)
    , BestTime(..)
    , NominalDistance(..)
    , BestDistance(..)
    , isNormal
    )

import Test.Tasty (TestTree, testGroup)
import Test.SmallCheck.Series as SC
import Test.Tasty.QuickCheck as QC
import Test.Tasty.HUnit as HU ((@?=), testCase)
import Data.UnitsOfMeasure (u)
import Data.UnitsOfMeasure.Internal (Quantity(..))

timeValidityUnits :: TestTree
timeValidityUnits = testGroup "Time validity unit tests"
    [ HU.testCase "Time validity 0 0 (Just 0) 0 = 0" $

        fst
        (FS.timeValidity
            (NominalTime . MkQuantity $ 0)
            (Just . BestTime . MkQuantity $ 0)
            (Just . BestTime . MkQuantity $ 0)
            (NominalDistance . MkQuantity $ 0)
            (BestDistance . MkQuantity $ 0))
        @?= TimeValidity 0

    , HU.testCase "Time validity 1 0 (Just 1) 0 = 1" $

        fst
        (FS.timeValidity
            (NominalTime . MkQuantity $ 1)
            (Just . BestTime . MkQuantity $ 1)
            (Just . BestTime . MkQuantity $ 1)
            (NominalDistance . MkQuantity $ 0)
            (BestDistance . MkQuantity $ 0))
        @?= TimeValidity 1

    , HU.testCase "Time validity 1 1 (Just 1) 1 = 1" $

        fst
        (FS.timeValidity
            (NominalTime . MkQuantity $ 1)
            (Just . BestTime . MkQuantity $ 1)
            (Just . BestTime . MkQuantity $ 1)
            (NominalDistance . MkQuantity $ 1)
            (BestDistance . MkQuantity $ 1))
        @?= TimeValidity 1

    , HU.testCase "Time validity 0 0 Nothing 0 = 0" $

        fst
        (FS.timeValidity
            (NominalTime . MkQuantity $ 0)
            Nothing
            Nothing
            (NominalDistance . MkQuantity $ 0)
            (BestDistance . MkQuantity $ 0))
        @?= TimeValidity 0

    , HU.testCase "Time validity 0 1 Nothing 1 = 1" $

        fst
        (FS.timeValidity
            (NominalTime . MkQuantity $ 0)
            Nothing
            Nothing
            (NominalDistance . MkQuantity $ 1)
            (BestDistance . MkQuantity $ 1))
        @?= TimeValidity 1

    , HU.testCase "Time validity 1 1 Nothing 1 = 1" $

        fst
        (FS.timeValidity
            (NominalTime . MkQuantity $ 1)
            Nothing
            Nothing
            (NominalDistance . MkQuantity $ 1)
            (BestDistance . MkQuantity $ 1))
        @?= TimeValidity 1
    ]

timeValidity
    :: NominalTime (Quantity Double [u| s |])
    -> Maybe (BestTime (Quantity Double [u| s |]))
    -> Maybe (BestTime (Quantity Double [u| s |]))
    -> NominalDistance (Quantity Double [u| km |])
    -> BestDistance (Quantity Double [u| km |])
    -> Bool
timeValidity nt ssT gsT nd d =
    (\(TimeValidity x) -> isNormal x) . fst
    $ FS.timeValidity nt ssT gsT nd d

scTimeValidity
    :: SC.NonNegative Double
    -> Maybe (SC.NonNegative Double)
    -> Maybe (SC.NonNegative Double)
    -> SC.NonNegative Double
    -> SC.NonNegative Double
    -> Bool
scTimeValidity
    (SC.NonNegative nt)
    ssT
    gsT
    (SC.NonNegative nd)
    (SC.NonNegative d) =
    timeValidity
        (NominalTime . MkQuantity $ nt)
        ((\(SC.NonNegative x) -> BestTime . MkQuantity $ x) <$> ssT)
        ((\(SC.NonNegative x) -> BestTime . MkQuantity $ x) <$> gsT)
        (NominalDistance . MkQuantity $ nd)
        (BestDistance . MkQuantity $ d)

qcTimeValidity
    :: QC.NonNegative Double 
    -> Maybe (QC.NonNegative Double)
    -> Maybe (QC.NonNegative Double)
    -> QC.NonNegative Double
    -> QC.NonNegative Double
    -> Bool
qcTimeValidity
    (QC.NonNegative nt)
    ssT
    gsT
    (QC.NonNegative nd)
    (QC.NonNegative d) =
    timeValidity
        (NominalTime . MkQuantity $ nt)
        ((\(QC.NonNegative x) -> BestTime . MkQuantity $ x) <$> ssT)
        ((\(QC.NonNegative x) -> BestTime . MkQuantity $ x) <$> gsT)
        (NominalDistance . MkQuantity $ nd)
        (BestDistance . MkQuantity $ d)
