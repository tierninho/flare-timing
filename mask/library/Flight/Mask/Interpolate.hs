{-# LANGUAGE FunctionalDependencies #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Flight.Mask.Interpolate
    ( TagInterpolate(..)
    , crossingTag
    ) where

import Prelude hiding (span)
import Data.Ratio ((%))
import Data.Time.Clock (NominalDiffTime, addUTCTime, diffUTCTime)
import Data.UnitsOfMeasure ((+:), (-:), (*:), u, convert)
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.LatLng (AzimuthFwd, Lat(..), Lng(..), LatLng(..))
import Flight.LatLng.Raw (RawLat(..), RawLng(..), RawAlt(..))
import qualified Flight.Track.Cross as Cg (Fix(..))
import Flight.Track.Cross (InterpolatedFix(..))
import Flight.Units ()
import Flight.Distance (SpanLatLng, TaskDistance(..), PathDistance(..))
import Flight.Task (Zs(..), distanceEdgeToEdge)
import Flight.Mask.Internal.Zone (TaskZone(..), fixToRadLL)
import Flight.Span.Sliver (Sliver(..))
import Flight.Zone (Zone(..))
import Flight.Zone.Path (distancePointToPoint)
import Flight.Zone.Cylinder (Tolerance(..))

class TagInterpolate a b | a -> b where
    interpolate
        :: (Real b, Fractional b)
        => a
        -> TaskZone b
        -> LatLng b [u| rad |]
        -> LatLng b [u| rad |]
        -> Zs ([LatLng b [u| rad |]])

    fractionate
        :: (Real b, Fractional b)
        => a
        -> Zs ([LatLng b [u| rad |]])
        -> Maybe (LatLng b [u| rad |], Double)

    spanner :: a -> SpanLatLng b
    azimuth :: a -> AzimuthFwd b

-- TODO: Find out why this cannot be implemented in terms of Quantity a u
linearInterpolate
    :: Num a
    => a
    -> Quantity a [u| m |]
    -> Quantity a [u| m |]
    -> Quantity a [u| m |]
linearInterpolate frac q0 q1 =
    ((MkQuantity frac :: Quantity _ [u| 1 |]) *: (q1 -: q0)) +: q0

instance TagInterpolate (Sliver a) a where
    interpolate sliver z x y = tagInterpolate sliver z x y
    fractionate sliver zs = tagFractionate sliver zs
    spanner Sliver{..} = span
    azimuth Sliver{..} = az

tagInterpolate
    :: forall a. (Real a, Fractional a)
    => Sliver a
    -> TaskZone a
    -> LatLng a [u| rad |]
    -> LatLng a [u| rad |]
    -> Zs ([LatLng a [u| rad |]])
tagInterpolate Sliver{..} (TaskZone z) x y =
    vertices <$> ee
    where
        zs' = [Point x, z, Point y]
        ee = distanceEdgeToEdge az span dpp cseg cs angleCut tolerance zs'

        tolerance = Tolerance . fromRational $ 1 % 10000

tagFractionate
    :: forall a. (Real a, Fractional a)
    => Sliver a
    -> Zs ([LatLng a [u| rad |]])
    -> Maybe (LatLng a [u| rad |], Double)
tagFractionate Sliver{..} (Zs [x, xy, y]) =
    Just (xy, realToFrac $ d0 / d1)
    where
        f xs = edgesSum $ distancePointToPoint span xs
        TaskDistance (MkQuantity d0) = f [Point x, Point xy]
        TaskDistance (MkQuantity d1) = f [Point x, Point y]

tagFractionate _ _ = Nothing

-- | Given two points on either side of a zone, what is the crossing tag.
crossingTag
    :: (Real b, Fractional b, TagInterpolate a b)
    => a
    -> TaskZone b
    -> (Cg.Fix, Cg.Fix)
    -> (Bool, Bool)
    -> Maybe InterpolatedFix

crossingTag
    f
    z
    ( m@Cg.Fix{fix, time = t0, alt = RawAlt a0}
    , n@Cg.Fix{time = t1, alt = RawAlt a1}
    )
    inZones

    | inZones == (True, False) || inZones == (False, True) = do
        let pts = interpolate f z (fixToRadLL m) (fixToRadLL n)
        (LatLng (Lat xLat, Lng xLng), frac) <- fractionate f pts
        let a0' :: Quantity _ [u| m |] = MkQuantity (fromRational a0)
        let a1' :: Quantity _ [u| m |] = MkQuantity (fromRational a1)
        let MkQuantity xAlt = linearInterpolate frac a0' a1'

        let MkQuantity xLat' = convert xLat :: Quantity _ [u| deg |]
        let MkQuantity xLng' = convert xLng :: Quantity _ [u| deg |]
        let secs :: NominalDiffTime = t1 `diffUTCTime` t0
        let secs' :: NominalDiffTime = secs * (realToFrac frac)

        return
            InterpolatedFix
                { fixFrac = fromIntegral fix + frac
                , time = secs' `addUTCTime` t0
                , lat = RawLat . fromRational . toRational $ xLat'
                , lng = RawLng . fromRational . toRational $ xLng'
                , alt = RawAlt . fromRational . toRational $ xAlt
                }

    | otherwise = Nothing


