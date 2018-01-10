{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NamedFieldPuns #-}

{-|
Module      : Flight.Track.Mask
Copyright   : (c) Block Scope Limited 2017
License     : BSD3
Maintainer  : phil.dejoux@blockscope.com
Stability   : experimental

Tracks masked with task control zones.
-}
module Flight.Track.Land
    ( Landing(..)
    ) where

import Data.String (IsString())
import GHC.Generics (Generic)
import Data.Aeson (ToJSON(..), FromJSON(..))
import Data.UnitsOfMeasure (u)
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.Field (FieldOrdering(..))
import Flight.Score
    ( Lookahead
    , Chunks
    , SumOfDifficulty
    , ChunkDifficulty
    )

-- | For each task, the masking for that task.
data Landing =
    Landing 
        { minDistance :: Double
        -- ^ The mimimum distance, set once for the comp. All pilots landing
        -- before this distance get this distance. The 100m segments start from
        -- here.
        , bestDistance :: [Maybe Double]
        -- ^ For each task, the best distance flown.
        , landout :: [Int]
        -- ^ For each task, the number of pilots landing out.
        , lookahead :: [Maybe Lookahead]
        -- ^ For each task, how many 100m chunks to look ahead for land outs.
        , sumOfDifficulty :: [Maybe SumOfDifficulty]
        -- ^ The difficulty of each chunk is relative to the sum of
        -- difficulties.
        , difficulty :: [Maybe [ChunkDifficulty]]
        -- ^ The difficulty of each chunk.
        , chunks :: [Chunks (Quantity Double [u| km |])]
        -- ^ For each task, the task distance to the end of each 100m chunk.
        }
        deriving (Eq, Ord, Show, Generic)

instance ToJSON Landing
instance FromJSON Landing

instance FieldOrdering Landing where
    fieldOrder _ = cmp

cmp :: (Ord a, IsString a) => a -> a -> Ordering
cmp a b =
    case (a, b) of
        ("chunk", _) -> LT

        ("down", "chunk") -> GT
        ("down", _) -> LT

        ("rel", "chunk") -> GT
        ("rel", "down") -> GT
        ("rel", _) -> LT

        ("frac", _) -> GT

        ("minDistance", _) -> LT

        ("bestDistance", "minDistance") -> GT
        ("bestDistance", _) -> LT

        ("landout", "minDistance") -> GT
        ("landout", "bestDistance") -> GT
        ("landout", _) -> LT

        ("lookahead", "minDistance") -> GT
        ("lookahead", "bestDistance") -> GT
        ("lookahead", "landout") -> GT
        ("lookahead", _) -> LT

        ("sumOfDifficulty", "minDistance") -> GT
        ("sumOfDifficulty", "bestDistance") -> GT
        ("sumOfDifficulty", "landout") -> GT
        ("sumOfDifficulty", "lookahead") -> GT
        ("sumOfDifficulty", _) -> LT

        ("difficulty", "minDistance") -> GT
        ("difficulty", "bestDistance") -> GT
        ("difficulty", "landout") -> GT
        ("difficulty", "lookahead") -> GT
        ("difficulty", "sumOfDifficulty") -> GT
        ("difficulty", _) -> LT

        ("chunks", _) -> GT

        _ -> compare a b
