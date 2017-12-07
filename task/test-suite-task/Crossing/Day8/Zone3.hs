{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE QuasiQuotes #-}

{-# LANGUAGE NamedFieldPuns #-}
{-# OPTIONS_GHC -fplugin Data.UnitsOfMeasure.Plugin #-}

module Crossing.Day8.Zone3 (units) where

import Test.Tasty (TestTree, testGroup)
import Test.Tasty.HUnit as HU (testCase)
import Test.Tasty.HUnit.Compare ((@?>=), (@?<=))
import Data.UnitsOfMeasure (u, unQuantity)

import qualified Flight.PointToPoint.Double as Dbl (distanceHaversine)
import Flight.Units ()
import Flight.Task (TaskDistance(..))
import EdgeToEdge (toLatLngDbl)

--     - - crossingPair:
--         - time: 2012-01-14T04:28:12Z
--            lat: -33.70837199
--            lng: 147.533598
--          - time: 2012-01-14T04:28:16Z
--            lat: -33.708866
--            lng: 147.533319
--          inZone:
--          - false
--          - true
--        - crossingPair:
--          - time: 2012-01-14T04:28:36Z
--            lat: -33.70895099
--            lng: 147.531538
--          - time: 2012-01-14T04:28:40Z
--            lat: -33.70837199
--            lng: 147.531474
--          inZone:
--          - true
--          - false
units :: TestTree
units = testGroup "Task 8 Zone 3 Crossings"
    [ HU.testCase "dy1" $ unQuantity dy1 @?>= r
    , HU.testCase "dz1" $ unQuantity dz1 @?<= r

    , HU.testCase "dy2" $ unQuantity dy2 @?<= r
    , HU.testCase "dz2" $ unQuantity dz2 @?>= r
    ]
    where
        -- MARSDE
        r = unQuantity [u| 5000m |]
        x = toLatLngDbl (negate 33.75343, 147.52864999)

        -- 2012-01-14T04:28:12/16
        y1 = toLatLngDbl (negate 33.70837199, 147.533598)
        z1 = toLatLngDbl (negate 33.708866, 147.533319)

        -- 2012-01-14T04:28:36/40
        y2 = toLatLngDbl (negate 33.70895099, 147.531538)
        z2 = toLatLngDbl (negate 33.70837199, 147.531474)

        (TaskDistance dy1) = Dbl.distanceHaversine x y1
        (TaskDistance dz1) = Dbl.distanceHaversine x z1

        (TaskDistance dy2) = Dbl.distanceHaversine x y2
        (TaskDistance dz2) = Dbl.distanceHaversine x z2
