module FlareTiming.Plot.Time (timePlot) where

import Data.Maybe (fromMaybe)
import Reflex.Dom

import qualified WireTypes.Point as Norm (NormBreakdown(..))
import WireTypes.Point (StartGate)
import WireTypes.Speed (TrackSpeed(..))
import WireTypes.Pilot (Pilot(..))
import qualified FlareTiming.Plot.Time.View as V (timePlot)

timePlot
    :: MonadWidget t m
    => Dynamic t [StartGate]
    -> Dynamic t [(Pilot, Norm.NormBreakdown)]
    -> Dynamic t (Maybe [(Pilot, TrackSpeed)])
    -> m ()
timePlot sgs sEx tm =
    elClass "div" "tile is-ancestor" $
        elClass "div" "tile is-12" $
            elClass "div" "tile" $
                elClass "div" "tile is-parent" $ do
                    _ <- dyn $ ffor tm (\case
                            Nothing ->
                                elClass "article" "tile is-child" $ do
                                    elClass "p" "title" $ text "Time"
                                    el "p" $ text "Loading times ..."

                            Just [] ->
                                elClass "article" "tile is-child notification is-warning" $ do
                                    elClass "p" "title" $ text "Time"
                                    el "p" $ text "No pilots made it to the end of the speed section. There are no arrivals and no time."

                            _ ->
                                elClass "article" "tile is-child" $
                                    V.timePlot sgs sEx (fromMaybe [] <$> tm))

                    return ()
