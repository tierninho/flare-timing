{-# LANGUAGE DuplicateRecordFields #-}

module WireTypes.Cross
    ( FlyingSection
    , TrackFlyingSection(..)
    , TrackScoredSection(..)
    , Fix(..)
    , InterpolatedFix(..)
    , ZoneTag(..)
    , ZoneCross(..)
    ) where

import Data.Time.Clock (UTCTime)
import GHC.Generics (Generic)
import Data.Aeson (FromJSON(..))
import WireTypes.Zone (RawLat(..), RawLng(..))

type FlyingSection a = Maybe (a, a)

data TrackFlyingSection =
    TrackFlyingSection
        { loggedFixes :: Maybe Int
        , flyingFixes :: FlyingSection Int
        }
    deriving (Eq, Ord, Show, Generic)
    deriving anyclass (FromJSON)

data TrackScoredSection =
    TrackScoredSection
        { scoredFixes :: FlyingSection Int
        }
    deriving (Eq, Ord, Show, Generic)
    deriving anyclass (FromJSON)

data Fix =
    Fix { fix :: Int
        , time :: UTCTime
        , lat :: RawLat
        , lng :: RawLng
        }
    deriving (Eq, Ord, Show, Generic)
    deriving anyclass (FromJSON)

data InterpolatedFix =
    InterpolatedFix
        { fixFrac :: Double
        , time :: UTCTime
        , lat :: RawLat
        , lng :: RawLng
        }
    deriving (Eq, Ord, Show, Generic)
    deriving anyclass (FromJSON)

data ZoneTag =
    ZoneTag
        { inter :: InterpolatedFix
        , cross :: ZoneCross
        }
    deriving (Eq, Ord, Show, Generic)
    deriving anyclass (FromJSON)

data ZoneCross =
    ZoneCross
        { crossingPair :: [Fix]
        , inZone :: [Bool]
        }
    deriving (Eq, Ord, Show, Generic)
    deriving anyclass (FromJSON)
