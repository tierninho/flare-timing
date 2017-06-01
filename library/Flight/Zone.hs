{-# LANGUAGE FlexibleInstances #-}

module Flight.Zone
    ( ShowAngle(..)
    , LatLng(..)
    , Radius(..)
    , Incline(..)
    , Bearing(..)
    , Zone(..)
    , Deadline(..)
    , TimeOfDay(..)
    , Interval(..)
    , StartGates(..)
    , Task(..)
    , TaskDistance(..)
    , earthRadius
    , distanceEdgeToEdge
    , distancePointToPoint
    , distanceHaversine
    , distanceHaversineF
    ) where

import Data.List (intercalate)
import Data.Ratio((%))
import qualified Data.Number.FixedFunctions as F

newtype LatLng = LatLng (Rational, Rational) deriving (Eq, Ord, Show)
newtype Radius = Radius Rational deriving (Eq, Ord, Show)
newtype Incline = Incline Rational deriving (Eq, Ord, Show)
newtype Bearing = Bearing Rational deriving (Eq, Ord, Show)

data Zone
    = Point LatLng
    | Vector LatLng Bearing
    | Cylinder LatLng Radius
    | Conical LatLng Radius Incline
    | Line LatLng Radius
    | SemiCircle LatLng Radius
    deriving (Eq, Show)

class ShowAngle a where
    showRadian :: a -> String

instance {-# OVERLAPPING #-} ShowAngle [ Zone ] where
    showRadian = showRadianZones

showRadianZones :: [Zone] -> String
showRadianZones xs = intercalate ", " $ showRadian <$> xs

instance ShowAngle Rational where
    showRadian x = show (fromRational x :: Double) ++ " rad"

instance ShowAngle LatLng where
    showRadian (LatLng (lat, lng)) =
        "(" ++ showRadian lat ++ ", " ++ showRadian lng ++ ")"

instance ShowAngle Zone where
    showRadian (Point x) = "Point " ++ showRadian x
    showRadian (Vector x _) = "Vector " ++ showRadian x
    showRadian (Cylinder x _) = "Cylinder " ++ showRadian x
    showRadian (Conical x _ _) = "Conical " ++ showRadian x
    showRadian (Line x _) = "Line " ++ showRadian x
    showRadian (SemiCircle x _) = "Semicircle " ++ showRadian x

newtype Deadline = Deadline Integer deriving (Eq, Ord, Show)
newtype TimeOfDay = TimeOfDay Rational deriving (Eq, Ord, Show)
newtype Interval = Interval Rational deriving (Eq, Ord, Show)

data StartGates
    = StartGates
        { open :: TimeOfDay
        , intervals :: [Interval]
        } deriving Show

data Task
    = Task
        { zones :: [Zone]
        , startZone :: Int
        , endZone :: Int
        , startGates :: StartGates
        , deadline :: Maybe Deadline
        } deriving Show

newtype TaskDistance = TaskDistance Rational deriving (Eq, Ord, Show)
newtype Epsilon = Epsilon Rational deriving (Eq, Ord, Show)

center :: Zone -> LatLng
center (Point x) = x
center (Vector x _) = x
center (Cylinder x _) = x
center (Conical x _ _) = x
center (Line x _) = x
center (SemiCircle x _) = x

earthRadius :: Rational
earthRadius = 6371000

distanceHaversineF :: LatLng -> LatLng -> TaskDistance
distanceHaversineF (LatLng (xLat, xLng)) (LatLng (yLat, yLng)) =
    TaskDistance $ earthRadius * toRational radDist 
    where
        distLat :: Rational
        distLat = yLat - xLat
         
        distLng :: Rational
        distLng = yLng - xLng

        haversine :: Rational -> Double
        haversine x =
            y * y
            where
                y :: Double
                y = sin $ fromRational (x * (1 % 2))

        a :: Double
        a =
            haversine distLat
            + cos (fromRational xLat)
            * cos (fromRational yLat)
            * haversine distLng

        radDist :: Double
        radDist = 2 * atan2 (sqrt a) (sqrt $ 1 - a)

distanceHaversine :: Epsilon -> LatLng -> LatLng -> TaskDistance
distanceHaversine (Epsilon eps) (LatLng (xLat, xLng)) (LatLng (yLat, yLng)) =
    TaskDistance $ 6371000 * radDist 
    where
        distLat :: Rational
        distLat = yLat - xLat
         
        distLng :: Rational
        distLng = yLng - xLng

        haversine :: Rational -> Rational
        haversine x =
            y * y
            where
                y :: Rational
                y = F.sin eps (x * (1 % 2))

        a :: Rational
        a =
            haversine distLat
            + F.cos eps xLat
            * F.cos eps yLat
            * haversine distLng

        radDist :: Rational
        radDist = 2 * F.atan eps ((F.sqrt eps a) / (F.sqrt eps $ 1 - a))

distancePointToPoint :: [Zone] -> TaskDistance
distancePointToPoint xs =
    TaskDistance $ sum $ zipWith f ys (tail ys)
    where
        ys = center <$> xs
        unwrap (TaskDistance x) = x
        f = (unwrap .) . distanceHaversineF

distanceEdgeToEdge :: [Zone] -> TaskDistance
distanceEdgeToEdge _ = TaskDistance 0
