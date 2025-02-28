{-|
Module      : Flight.Track.Mask.Arrrival
Copyright   : (c) Block Scope Limited 2017
License     : MPL-2.0
Maintainer  : phil.dejoux@blockscope.com
Stability   : experimental

Tracks masked with task control zones.
-}
module Flight.Track.Mask.Arrival (MaskingArrival (..)) where

import GHC.Generics (Generic)
import Data.Aeson (ToJSON(..), FromJSON(..))

import Flight.Score (Pilot(..), PilotsAtEss(..))
import Flight.Field (FieldOrdering(..))
import Flight.Units ()
import Flight.Track.Arrival (TrackArrival(..))
import Flight.Track.Mask.Cmp (cmp)

-- | For each task, the masking for arrival for that task.
data MaskingArrival =
    MaskingArrival
        { pilotsAtEss :: [PilotsAtEss]
        -- ^ For each task, the number of pilots at goal.
        , arrivalRank :: [[(Pilot, TrackArrival)]]
        -- ^ For each task, the rank order of arrival at goal and arrival fraction.
        }
    deriving (Eq, Ord, Show, Generic, ToJSON, FromJSON)

instance FieldOrdering MaskingArrival where fieldOrder _ = cmp
