module FlareTiming.Task.Absent (tableAbsent) where

import Reflex.Dom

import WireTypes.Comp (Task(..), getAbsent)
import FlareTiming.Pilot (rowPilot)

tableAbsent
    :: MonadWidget t m
    => Dynamic t Task
    -> m ()
tableAbsent x = do
    let xs = getAbsent <$> x

    _ <- elClass "table" "table" $
            el "thead" $ do
                el "tr" $ do
                    el "th" $ text "Id"
                    el "th" $ text "Name"

                simpleList xs rowPilot
    return ()
