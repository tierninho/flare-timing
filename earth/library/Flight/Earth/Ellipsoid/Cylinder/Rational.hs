module Flight.Earth.Ellipsoid.Cylinder.Rational
    ( circumSample
    , vincentyDirect
    , cos2
    ) where

import qualified Data.Number.FixedFunctions as F
import Data.UnitsOfMeasure (u, convert, fromRational', toRational')
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.LatLng (Lat(..), Lng(..), LatLng(..))
import Flight.LatLng.Rational (Epsilon(..), defEps)
import Flight.Zone
    ( Zone(..)
    , QRadius
    , Radius(..)
    , Bearing(..)
    , ArcSweep(..)
    , center
    , radius
    , fromRationalRadius
    , toRationalZone
    , fromRationalLatLng
    , toRationalLatLng
    )
import Flight.Zone.Path (distancePointToPoint)
import Flight.Earth.Ellipsoid.PointToPoint.Rational (distanceVincenty)
import Flight.Distance (TaskDistance(..), PathDistance(..))
import Flight.Zone.Cylinder
    ( TrueCourse(..)
    , ZonePoint(..)
    , Tolerance(..)
    , SampleParams(..)
    , CircumSample
    , orbit
    , radial
    , point
    , sourceZone
    , fromRationalZonePoint
    , sampleAngles
    )
import Flight.Earth.Ellipsoid
    (Ellipsoid(..), VincentyDirect(..), VincentyAccuracy(..)
    , defaultVincentyAccuracy, wgs84, flattening, polarRadius
    )
import qualified Flight.Earth.Ellipsoid.Cylinder.Double as Dbl (vincentyDirect)
import Flight.Earth.Geodesy (DirectProblem(..), DirectSolution(..))
import Flight.Earth.Ellipsoid.Cylinder.Double (cos2)
import qualified Flight.Earth.Math as F (atan2')
import Flight.Earth.ZoneShape.Rational (PointOnRadial, onLine)

iterateVincenty
    :: Epsilon
    -> VincentyAccuracy Rational
    -> Rational
    -> Rational
    -> Rational
    -> Rational
    -> Rational
    -> Rational
    -> Rational
iterateVincenty
    epsilon@(Epsilon eps)
    accuracy@(VincentyAccuracy tolerance)
    _A
    _B
    s
    b
    σ1
    σ =
    if abs (σ - σ') < tolerance
       then σ 
       else iterateVincenty epsilon accuracy _A _B s b σ1 σ'
    where
        (cos2σm, cos²2σm) = cos2 cos' σ1 σ
        sinσ = sin' σ
        cosσ = cos' σ
        sin²σ = sinσ * sinσ

        _Δσ =
            _B * sinσ *
                (cos2σm + _B / 4 *
                    (cosσ * (-1 + 2 * cos²2σm)
                    - _B / 6
                    * cos2σm
                    * (-3 + 4 * sin²σ)
                    * (-3 + 4 * cos²2σm)
                    )
                )

        σ' = s / b * _A + _Δσ

        sin' = F.sin eps
        cos' = F.cos eps

vincentyDirect'
    :: Epsilon
    -> Ellipsoid Rational
    -> VincentyAccuracy Rational
    -> DirectProblem
        (LatLng Rational [u| rad |])
        (TrueCourse Rational)
        (QRadius Rational [u| m |])
    -> VincentyDirect
        (DirectSolution
            (LatLng Rational [u| rad |])
            (TrueCourse Rational)
        )
vincentyDirect'
    epsilon@(Epsilon eps)
    ellipsoid@Ellipsoid{equatorialR = Radius (MkQuantity a)}
    accuracy
    DirectProblem
        { x = (LatLng (Lat (MkQuantity _Φ1), Lng (MkQuantity _L1)))
        , α₁= TrueCourse (MkQuantity α1)
        , s = Radius (MkQuantity s)
        } =
    if (cosU1 * cosσ - sinU1 * sinσ * cosα1) == 0 then VincentyDirectEquatorial else
    VincentyDirect $
    DirectSolution
        { y = LatLng (Lat . MkQuantity $ _Φ2, Lng . MkQuantity $ _L2)
        , α₂ = Just . TrueCourse . MkQuantity $ sinα / (-j)
        }
    where
        MkQuantity b = polarRadius ellipsoid
        f = flattening ellipsoid

        -- Initial setup
        _U1 = atan' $ (1 - f) * tan' _Φ1
        σ1 = atan2' (tan' _U1) (cos' α1)
        sinα = cos' _U1 * sin' α1
        sin²α = sinα * sinα
        cos²α = 1 - sin²α 
        _A = 1 + u² / 16384 * (4096 + u² * (-768 + u² * (320 - 175 * u²)))
        _B = u² / 1024 * (256 + u² * (-128 + u² * (74 - 47 * u²)))

        -- Solution
        σ = iterateVincenty epsilon accuracy _A _B s b σ1 (s / (b * _A))
        sinσ = sin' σ
        cosσ = cos' σ
        cosα1 = cos' α1
        sinU1 = sin' _U1
        cosU1 = cos' _U1
        v = sinU1 * cosσ + cosU1 * sinσ * cosα1
        j = sinU1 * sinσ - cosU1 * cosσ * cosα1
        w = (1 - f) * sqrt' (sin²α + j * j)
        _Φ2 = atan2' v w
        λ = atan2' (sinσ * sin' α1) (cosU1 * cosσ - sinU1 * sinσ * cosα1)
        _C = f / 16 * cos²α * (4 - 3 * cos²α)

        (cos2σm, cos²2σm) = cos2 cos' σ1 σ
        x = σ + _C * sinσ * y
        y = cos' (2 * cos2σm + _C * cosσ * (-1 + 2 * cos²2σm))
        _L = λ * (1 - _C) * f * sinα * x

        _L2 = _L + _L1

        sin' = F.sin eps
        cos' = F.cos eps
        tan' = F.tan eps
        atan' = F.atan eps
        sqrt' = F.sqrt eps
        atan2' = F.atan2' epsilon

        a² = a * a
        b² = b * b
        u² = cos²α * (a² - b²) / b² 

vincentyDirect
    :: Epsilon
    -> Ellipsoid Rational
    -> VincentyAccuracy Rational
    -> DirectProblem
        (LatLng Rational [u| rad |])
        (TrueCourse Rational)
        (QRadius Rational [u| m |])
    -> VincentyDirect
        (DirectSolution
            (LatLng Rational [u| rad |])
            (TrueCourse Rational)
        )
vincentyDirect
    e ellipsoid accuracy
    prob@DirectProblem
        { x = x@(LatLng (xLat, xLng))
        , α₁ = (TrueCourse b)
        , s = r
        }

    -- NOTE: If we have an initial point at the poles then defer to the
    -- solution using doubles.
    | xLat == minBound = v'
    | xLat == maxBound = v'

    -- NOTE: If we have an initial point out of bounds defer to the
    -- solution using doubles.
    | xLat < minBound = v'
    | xLat > maxBound = v'

    | xLng <= minBound = v'
    | xLng >= maxBound = v'

    | xLng < (Lng $ convert [u| -179 deg |]) = v'
    | xLng > (Lng $ convert [u| 179 deg |]) = v'

    -- NOTE: If we have an azimuth of due east or west then defer to the
    -- solution using doubles.
    | b' > [u| 89 deg |] && b' < [u| 91 deg |] = v'
    | b' > [u| 269 deg |] && b' < [u| 271 deg |]  = v'

    | otherwise =
        case vincentyDirect' e ellipsoid accuracy prob of
            v@(VincentyDirect _) -> v
            _ -> v'
    where
        VincentyAccuracy accuracy' = accuracy
        accuracy'' = VincentyAccuracy $ fromRational accuracy'

        b' :: Quantity Double [u| deg |]
        b' = convert . fromRational' $ b

        prob'
            :: DirectProblem
                (LatLng Double [u| rad |])
                (TrueCourse Double)
                (QRadius Double [u| m |])
        prob' =
            DirectProblem
                { x = fromRationalLatLng x
                , α₁ = TrueCourse . fromRational' $ b
                , s = fromRationalRadius r
                }

        v'
            :: VincentyDirect
                (DirectSolution
                    (LatLng Rational [u| rad |])
                    (TrueCourse Rational)
                )
        v' =
            case Dbl.vincentyDirect wgs84 accuracy'' prob' of
                VincentyDirectAbnormal ab -> VincentyDirectAbnormal ab
                VincentyDirectEquatorial -> VincentyDirectEquatorial
                VincentyDirectAntipodal -> VincentyDirectAntipodal
                VincentyDirect soln ->
                    VincentyDirect $ toRationalDirectSolution soln

toRationalDirectSolution
    :: DirectSolution (LatLng Double [u| rad |]) (TrueCourse Double)
    -> DirectSolution (LatLng Rational [u| rad |]) (TrueCourse Rational)
toRationalDirectSolution DirectSolution{y, α₂} =
    DirectSolution
        { y = toRationalLatLng y
        , α₂ = toRationalTrueCourse <$> α₂
        }
    where
        toRationalTrueCourse (TrueCourse x) =
            TrueCourse $ toRational' x

circum
    :: Epsilon
    -> LatLng Rational [u| rad |]
    -> QRadius Rational [u| m |]
    -> TrueCourse Rational 
    -> LatLng Rational [u| rad |]
circum e x r tc =
    case vincentyDirect e wgs84 defaultVincentyAccuracy prob of
        VincentyDirectAbnormal _ -> error "Vincenty direct abnormal"
        VincentyDirectEquatorial -> error "Vincenty direct equatorial"
        VincentyDirectAntipodal -> error "Vincenty direct antipodal"
        VincentyDirect DirectSolution{y} -> y
    where
        prob =
            DirectProblem
                { x = x
                , α₁ = tc
                , s = r
                }

-- | Generates a pair of lists, the lat/lng of each generated point
-- and its distance from the center. It will generate 'samples' number of such
-- points that should lie close to the circle. The difference between
-- the distance to the origin and the radius should be less han the 'tolerance'.
--
-- The points of the compass are divided by the number of samples requested.
circumSample :: CircumSample Rational
circumSample sp@SampleParams{..} arcSweep@(ArcSweep (Bearing (MkQuantity bearing))) arc0 zoneM zoneN
    | bearing < 0 || bearing > 2 * F.pi eps = fail "Arc sweep must be in the range 0..2π radians."
    | otherwise =
        case (zoneM, zoneN) of
            (Nothing, _) -> ys
            (Just _, Point _) -> ys
            (Just _, Vector _ _) -> ys
            (Just _, Cylinder _ _) -> ys
            (Just _, Conical _ _ _) -> ys
            (Just _, Line _ _ _) -> onLine defEps mkLinePt θ ys
            (Just _, Circle _ _) -> ys
            (Just _, SemiCircle _ _ _) -> ys
    where
        (Epsilon eps) = defEps

        zone' :: Zone Rational
        zone' =
            case arc0 of
              Nothing -> zoneN
              Just ZonePoint{..} -> sourceZone

        (θ, xs) = sampleAngles (F.pi eps) sp arcSweep arc0 zoneM zoneN

        (Radius (MkQuantity limitRadius)) = radius zone'
        limitRadius' = toRational limitRadius
        r = Radius (MkQuantity limitRadius')

        ptCenter = center zone'
        circumR = circum defEps ptCenter

        getClose' = getClose defEps zone' ptCenter limitRadius' spTolerance

        mkLinePt :: PointOnRadial
        mkLinePt _ (Bearing b) rLine = circumR rLine $ TrueCourse b

        ys' :: ([ZonePoint Rational], [TrueCourse Rational])
        ys' = unzip $ getClose' 10 (Radius (MkQuantity 0)) (circumR r) <$> xs

        ys = (fromRationalZonePoint <$> fst ys', snd ys')

getClose
    :: Epsilon
    -> Zone Rational
    -> LatLng Rational [u| rad |] -- ^ The center point.
    -> Rational -- ^ The limit radius.
    -> Tolerance Rational
    -> Int -- ^ How many tries.
    -> QRadius Rational [u| m |] -- ^ How far from the center.
    -> (TrueCourse Rational -> LatLng Rational [u| rad |]) -- ^ A point from the origin on this radial
    -> TrueCourse Rational -- ^ The true course for this radial.
    -> (ZonePoint Rational, TrueCourse Rational)
getClose epsilon zone' ptCenter limitRadius spTolerance trys yr@(Radius (MkQuantity offset)) f x@(TrueCourse tc)
    | trys <= 0 = (zp', x)
    | unTolerance spTolerance <= 0 = (zp', x)
    | limitRadius <= unTolerance spTolerance = (zp', x)
    | otherwise =
        case d `compare` limitRadius of
             EQ ->
                 (zp', x)

             GT ->
                 let offset' =
                         offset - (d - limitRadius) * 105 / 100

                     f' =
                         circumR (Radius (MkQuantity $ limitRadius + offset'))

                 in
                     getClose
                         epsilon
                         zone'
                         ptCenter
                         limitRadius
                         spTolerance
                         (trys - 1)
                         (Radius (MkQuantity offset'))
                         f'
                         x

             LT ->
                 if d > toRational (limitRadius - unTolerance spTolerance)
                 then (zp', x)
                 else
                     let offset' =
                             offset + (limitRadius - d) * 94 / 100

                         f' =
                             circumR (Radius (MkQuantity $ limitRadius + offset'))
                     in
                         getClose
                             epsilon
                             zone'
                             ptCenter
                             limitRadius
                             spTolerance
                             (trys - 1)
                             (Radius (MkQuantity offset'))
                             f'
                             x
    where
        circumR = circum epsilon ptCenter

        y = f x
        zp' = ZonePoint { sourceZone = toRationalZone zone'
                        , point = y
                        , radial = Bearing tc
                        , orbit = yr
                        } :: ZonePoint Rational

        (TaskDistance (MkQuantity d)) =
            edgesSum
            $ distancePointToPoint
                (distanceVincenty defEps wgs84)
                [Point ptCenter, Point y]
