{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE TypeOperators #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE QuasiQuotes #-}

{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# OPTIONS_GHC -fplugin Data.UnitsOfMeasure.Plugin #-}

module Zone
    ( QLL, MkZone
    , point, vector, cylinder, line, conical, semicircle
    , dotZones, areaZones, describedZones
    , showQ
    ) where

import Data.UnitsOfMeasure (u, zero, toRational')
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.Units.DegMinSec (fromQ)
import Flight.LatLng (Lat(..), Lng(..), LatLng(..))
import Flight.Zone
    ( Zone(..)
    , Radius(..)
    , Incline (..)
    , Bearing(..)
    , toRationalRadius
    , realToFracLatLng
    , fromRationalZone
    )

type QLL a = (Quantity a [u| rad |], Quantity a [u| rad |])
type MkZone a b = Real a => Radius a [u| m |] -> QLL a -> Zone b

showQ :: Real a => QLL a -> String
showQ (x, y) =
    show (fromQ x', fromQ y')
    where
        LatLng (Lat x', Lng y') = realToFracLatLng . LatLng $ (Lat x, Lng y)

toLL :: Real a => QLL a -> LatLng Rational [u| rad |]
toLL (lat, lng) =
    LatLng (Lat lat', Lng lng')
    where
        lat' = toRational' lat
        lng' = toRational' lng

point :: (Eq b, Fractional b) => MkZone a b
point _ x =
    fromRationalZone
    $ Point (toLL x)

vector :: (Eq b, Fractional b) => MkZone a b
vector _ x =
    fromRationalZone
    $ Vector (Bearing zero) (toLL x) 

cylinder :: (Eq b, Fractional b) => MkZone a b
cylinder r x =
    fromRationalZone
    $ Cylinder (toRationalRadius r) (toLL x)

conical :: (Eq b, Fractional b) => MkZone a b
conical r x =
    fromRationalZone
    $ Conical (Incline $ MkQuantity 1) (toRationalRadius r) (toLL x)

line :: (Eq b, Fractional b) => MkZone a b
line r x =
    fromRationalZone
    $ Line (toRationalRadius r) (toLL x) 

semicircle :: (Eq b, Fractional b) => MkZone a b
semicircle r x =
    fromRationalZone
    $ SemiCircle (toRationalRadius r) (toLL x)

describedZones
    :: (Real a, Fractional a)
    =>
        [
            ( String
            , Radius a [u| m |] -> QLL a -> Zone a
            )
        ]
describedZones =
    dotZones ++ areaZones

dotZones
    :: (Real a, Fractional a)
    =>
        [
            ( String
            , Radius a [u| m |] -> QLL a -> Zone a
            )
        ]
dotZones =
    [ ("point", point)
    , ("vector", vector)
    ]

areaZones
    :: (Real a, Fractional a)
    =>
        [
            ( String
            , Radius a [u| m |] -> QLL a -> Zone a
            )
        ]
areaZones =
    [ ("cylinder", cylinder)
    , ("conical", conical)
    , ("line", line)
    , ("semicircle", semicircle)
    ]
