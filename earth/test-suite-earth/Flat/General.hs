{-# OPTIONS_GHC -fplugin Data.UnitsOfMeasure.Plugin #-}

module Flat.General
    ( zoneUnits
    , distancePoint
    , distanceEuclidean
    , distanceEuclideanF
    ) where

import Prelude hiding (span)
import Data.Ratio ((%))
import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit as HU ((@?=), testCase)
import Data.UnitsOfMeasure (u, zero)
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.LatLng (Lat(..), Lng(..), LatLng(..))
import Flight.Distance (TaskDistance(..), PathDistance(..), SpanLatLng)
import Flight.Zone
    ( Zone(..)
    , Radius(..)
    , Incline (..)
    , Bearing(..)
    , center
    )
import Flight.Zone.Path (distancePointToPoint)
import qualified Flight.Earth.Flat.PointToPoint.Double as Dbl (distanceEuclidean)
import qualified Flight.Earth.Flat.PointToPoint.Rational as Rat (distanceEuclidean)
import Flight.Earth.Flat.Separated (separatedZones)

import Props.Zone (ZonesTest(..))
import Props.Euclidean (EuclideanTest(..))

-- | The radius of the earth in the FAI sphere is 6,371 km.
earthRadius :: Num a => Quantity a [u| m |]
earthRadius = [u| 6371000 m |]

type Pt = (Rational, Rational)

toLL :: (Rational, Rational) -> LatLng Rational [u| rad |]
toLL (lat, lng) =
    LatLng (Lat lat', Lng lng')
    where
        lat' = MkQuantity lat
        lng' = MkQuantity lng

point :: (Rational, Rational) -> Zone Rational
point x =
    Point $ toLL x

vector :: (Rational, Rational) -> Zone Rational
vector x =
    Vector (Bearing zero) (toLL x) 

cylinder :: (Rational, Rational) -> Zone Rational
cylinder x =
    Cylinder (Radius earthRadius) (toLL x)

conical :: (Rational, Rational) -> Zone Rational
conical x =
    Conical (Incline $ MkQuantity 1) (Radius earthRadius) (toLL x)

line :: (Rational, Rational) -> Zone Rational
line x =
    Line (Radius earthRadius) (toLL x) 

semicircle :: (Rational, Rational) -> Zone Rational
semicircle x =
    SemiCircle (Radius earthRadius) (toLL x)

zoneUnits :: TestTree
zoneUnits =
    testGroup "Zone unit tests"
    [ distanceUnits
    , coincidentUnits
    , touchingUnits
    , disjointUnits
    ]

distanceUnits :: TestTree
distanceUnits =
    testGroup "Point-to-point distance"
    [ emptyDistance
    , pointDistance
    , vectorDistance
    , cylinderDistance
    , conicalDistance
    , lineDistance
    , semicircleDistance
    ]

coincidentUnits :: TestTree
coincidentUnits =
    testGroup "Coincident zone separation"
    [ pointCoincident
    , vectorCoincident
    , cylinderCoincident
    , conicalCoincident
    , lineCoincident
    , semicircleCoincident
    ]

touchingUnits :: TestTree
touchingUnits =
    testGroup "Touching zone separation"
    [ cylinderTouching
    , conicalTouching
    , lineTouching
    , semicircleTouching
    ]

disjointUnits :: TestTree
disjointUnits =
    testGroup "Disjoint zone separation"
    [ pointDisjoint
    , vectorDisjoint
    , cylinderDisjoint
    , conicalDisjoint
    , lineDisjoint
    , semicircleDisjoint
    ]

emptyDistance :: TestTree
emptyDistance = testGroup "Point-to-point distance"
    [ HU.testCase "No zones = zero point-to-point distance" $
        edgesSum (distancePointToPoint span []) @?= (TaskDistance $ MkQuantity 0)
    ]

toDistance :: String -> [[Zone Rational]] -> TestTree
toDistance title xs =
    testGroup title (f <$> xs)
    where
        f x =
            HU.testCase (mconcat [ "distance ", show x, " = earth radius" ]) $
                edgesSum (distancePointToPoint span x)
                    @?= TaskDistance earthRadius

ptsDistance :: [[Pt]]
ptsDistance =
    [ [ (1, 0), (0, 0) ]
    , [ (0, 1), (0, 0) ]
    , [ (0, 0), (0, 1) ]
    , [ (0, 0), (1, 0) ]
    ]

pointDistance :: TestTree
pointDistance = toDistance "Distance over point zones" ((fmap . fmap) point ptsDistance)

vectorDistance :: TestTree
vectorDistance = toDistance "Distance over vector zones" ((fmap . fmap) vector ptsDistance)

cylinderDistance :: TestTree
cylinderDistance = toDistance "Distance over cylinder zones" ((fmap . fmap) cylinder ptsDistance)

conicalDistance :: TestTree
conicalDistance = toDistance "Distance over conical zones" ((fmap . fmap) conical ptsDistance)

lineDistance :: TestTree
lineDistance = toDistance "Distance over line zones" ((fmap . fmap) line ptsDistance)

semicircleDistance :: TestTree
semicircleDistance = toDistance "Distance over semicircle zones" ((fmap . fmap) semicircle ptsDistance)

coincident :: String -> [[Zone Rational]] -> TestTree
coincident title xs =
    testGroup title (f <$> xs)
    where
        f x =
            HU.testCase (mconcat [ "concident pair of "
                                 , show $ head x
                                 , " = not separate"
                                 ]) $
                separatedZones span x
                    @?= False

ptsCoincident :: [[Pt]]
ptsCoincident =
    [ [ (1, 0), (1, 0) ]
    , [ (0, 1), (0, 1) ]
    , [ (1, 0), (1, 0) ]
    , [ (1, 1), (1, 1) ]
    ]

pointCoincident :: TestTree
pointCoincident = coincident "Point zones" ((fmap . fmap) point ptsCoincident)

vectorCoincident :: TestTree
vectorCoincident = coincident "Vector zones" ((fmap . fmap) vector ptsCoincident)

cylinderCoincident :: TestTree
cylinderCoincident = coincident "Cylinder zones" ((fmap . fmap) cylinder ptsCoincident)

conicalCoincident :: TestTree
conicalCoincident = coincident "Conical zones" ((fmap . fmap) conical ptsCoincident)

lineCoincident :: TestTree
lineCoincident = coincident "Line zones" ((fmap . fmap) line ptsCoincident)

semicircleCoincident :: TestTree
semicircleCoincident = coincident "Semicircle zones" ((fmap . fmap) semicircle ptsCoincident)

touching :: String -> [[Zone Rational]] -> TestTree
touching title xs =
    testGroup title (f <$> xs)
    where
        f x =
            HU.testCase (mconcat [ "touching pair of "
                                 , show x
                                 , " = not separate"
                                 ]) $
                separatedZones span x
                    @?= False

epsM :: Rational
epsM = 2 % 1 - 1 % 100000000

radiiTouching :: [[Pt]]
radiiTouching =
    [ [ (0, epsM), (0, 0) ]
    , [ (0, negate epsM), (0, 0) ]
    ]

cylinderTouching :: TestTree
cylinderTouching = touching "Cylinder zones" ((fmap . fmap) cylinder radiiTouching)

conicalTouching :: TestTree
conicalTouching = touching "Conical zones" ((fmap . fmap) conical radiiTouching)

lineTouching :: TestTree
lineTouching = touching "Line zones" ((fmap . fmap) line radiiTouching)

semicircleTouching :: TestTree
semicircleTouching = touching "Semicircle zones" ((fmap . fmap) semicircle radiiTouching)

disjoint :: String -> [[Zone Rational]] -> TestTree
disjoint title xs =
    testGroup title (f <$> xs)
    where
        f x =
            HU.testCase (mconcat [ "disjoint pair of "
                                 , show x 
                                 , " = separate"
                                 ]) $
                separatedZones span x
                    @?= True

eps :: Rational
eps = 2 % 1 + 1 % 100000000

ptsDisjoint :: [[Pt]]
ptsDisjoint =
    [ [ (0, eps), (0, 0) ]
    , [ (0, negate eps), (1, 0) ]
    ]

epsR :: Rational
epsR = 2 % 1 + 1 % 100000000

radiiDisjoint :: [[Pt]]
radiiDisjoint =
    [ [ (0, epsR), (0, 0) ]
    , [ (0, negate epsR), (0, 0) ]
    ]

pointDisjoint :: TestTree
pointDisjoint = disjoint "Point zones" ((fmap . fmap) point ptsDisjoint)

vectorDisjoint :: TestTree
vectorDisjoint = disjoint "Vector zones" ((fmap . fmap) vector ptsDisjoint)

cylinderDisjoint :: TestTree
cylinderDisjoint = disjoint "Cylinder zones" ((fmap . fmap) cylinder radiiDisjoint)

conicalDisjoint :: TestTree
conicalDisjoint = disjoint "Conical zones" ((fmap . fmap) conical radiiDisjoint)

lineDisjoint :: TestTree
lineDisjoint = disjoint "Line zones" ((fmap . fmap) line radiiDisjoint)

semicircleDisjoint :: TestTree
semicircleDisjoint = disjoint "Semicircle zones" ((fmap . fmap) semicircle radiiDisjoint)

correctPoint :: [Zone Rational] -> TaskDistance Rational -> Bool
correctPoint [] (TaskDistance (MkQuantity d)) = d == 0
correctPoint [_] (TaskDistance (MkQuantity d)) = d == 0
correctPoint [Cylinder xR x, Cylinder yR y] (TaskDistance (MkQuantity d))
    | x == y = (xR == yR && d == 0) || d > 0
    | otherwise = d > 0
correctPoint xs (TaskDistance (MkQuantity d))
    | all (== head ys) (tail ys) = d == 0
    | otherwise = d > 0
    where
        ys = center <$> xs

distanceEuclideanF :: EuclideanTest Double -> Bool
distanceEuclideanF (EuclideanTest (x, y)) =
    [u| 0 m |] <= d
    where
        TaskDistance d = Dbl.distanceEuclidean x y

distanceEuclidean :: EuclideanTest Rational -> Bool
distanceEuclidean (EuclideanTest (x, y)) =
    [u| 0 m |] <= d
    where
        TaskDistance d = Rat.distanceEuclidean x y

distancePoint :: ZonesTest Rational -> Bool
distancePoint (ZonesTest xs) =
    (\(PathDistance d _) -> correctPoint xs d)
    $ distancePointToPoint span xs

span :: SpanLatLng Rational
span = Rat.distanceEuclidean
