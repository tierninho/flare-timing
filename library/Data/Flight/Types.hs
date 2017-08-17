{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}

module Data.Flight.Types
    ( Fix(..)
    , LLA(..)
    , LatLngAlt(..)
    , FixMark(..)
    , Seconds(..)
    , Latitude(..)
    , Longitude(..)
    , Altitude(..)
    , MarkedFixes(..)
    , mkPosition
    ) where

import Data.Time.Clock (UTCTime)
import GHC.Generics (Generic)
import Data.Aeson (ToJSON(..), FromJSON(..))

newtype Latitude = Latitude Rational deriving (Show, Eq, Generic)
newtype Longitude = Longitude Rational deriving (Show, Eq, Generic)
newtype Altitude = Altitude Integer deriving (Show, Eq, Ord, Num, Generic)
newtype Seconds = Seconds Integer deriving (Show, Eq, Ord, Num, Generic)

instance ToJSON Latitude
instance FromJSON Latitude

instance ToJSON Longitude
instance FromJSON Longitude

instance ToJSON Altitude
instance FromJSON Altitude

instance ToJSON Seconds
instance FromJSON Seconds

data LLA =
    LLA { llaLat :: Latitude
        , llaLng :: Longitude
        , llaAltGps :: Altitude
        } deriving (Eq, Show, Generic)

instance ToJSON LLA
instance FromJSON LLA

data Fix =
    Fix { fixMark :: Seconds
        , fix :: LLA
        , fixAltBaro :: Maybe Altitude
        } deriving (Eq, Show, Generic)

instance ToJSON Fix
instance FromJSON Fix

mkPosition :: (Latitude, Longitude, Altitude) -> LLA
mkPosition (lat', lng', alt') = LLA lat' lng' alt'

class LatLngAlt a where
    lat :: a -> Latitude
    lng :: a -> Longitude
    altGps :: a -> Altitude

instance LatLngAlt LLA where
    lat LLA{llaLat} = llaLat
    lng LLA{llaLng} = llaLng
    altGps LLA{llaAltGps} = llaAltGps

instance LatLngAlt Fix where
    lat Fix{fix} = lat fix
    lng Fix{fix} = lng fix
    altGps Fix{fix} = altGps fix

class LatLngAlt a => FixMark a where
    mark :: a -> Seconds
    altBaro :: a -> Maybe Altitude

instance FixMark Fix where
    mark Fix{fixMark} = fixMark
    altBaro Fix{fixAltBaro} = fixAltBaro

data MarkedFixes =
    MarkedFixes { mark0 :: UTCTime
                , fixes :: [Fix]
                } deriving (Show, Eq, Generic)

instance ToJSON MarkedFixes
instance FromJSON MarkedFixes
