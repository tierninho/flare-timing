{-# LANGUAGE DataKinds #-}
{-# LANGUAGE QuasiQuotes #-}

{-# OPTIONS_GHC -fplugin Data.UnitsOfMeasure.Plugin #-}

module Ellipsoid.Distance where

import Prelude hiding (span)
import Test.Tasty (TestTree)
import Data.UnitsOfMeasure (u)
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.LatLng.Rational (defEps)
import Flight.Distance (SpanLatLng)
import Flight.Zone (Zone(..))
import qualified Flight.Earth.Ellipsoid.PointToPoint.Rational as Rat
    (distanceVincenty)
import Flight.Earth.Ellipsoid (wgs84)
import qualified Distance as D

span :: SpanLatLng Rational
span = Rat.distanceVincenty defEps wgs84

toDistanceEqual
    :: Quantity Rational [u| m |]
    -> String
    -> (Zone Rational, Zone Rational)
    -> TestTree
toDistanceEqual = D.toDistanceEqual span

toDistanceClose
    :: Quantity Rational [u| mm |]
    -> Quantity Rational [u| m |]
    -> String
    -> (Zone Rational, Zone Rational)
    -> TestTree
toDistanceClose = D.toDistanceClose span
