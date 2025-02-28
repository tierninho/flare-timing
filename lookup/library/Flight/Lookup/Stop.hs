module Flight.Lookup.Stop
    ( ScoredLookup(..)
    , stopFlying
    ) where

import Data.List (find)
import Control.Lens ((^?), element)
import Flight.Comp (IxTask(..), Pilot(..))
import Flight.Track.Stop (TrackScoredSection(..))
import qualified Flight.Track.Stop as S (Framing(..))

type StopLookup a = IxTask -> Pilot -> Maybe a

newtype ScoredLookup =
    ScoredLookup (Maybe (StopLookup TrackScoredSection))

stopFlying :: Maybe S.Framing -> ScoredLookup
stopFlying = ScoredLookup . (fmap flyingTask)

flyingTask :: S.Framing -> IxTask -> Pilot -> Maybe TrackScoredSection
flyingTask S.Framing{stopFlying = xs} (IxTask i) pilot =
    case xs ^? element (fromIntegral i - 1) of
        Nothing -> Nothing
        Just ys -> snd =<< find (\(p, _) -> p == pilot) ys
