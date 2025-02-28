module FlareTiming.Task.Absent (tableAbsent) where

import Prelude hiding (abs)
import Reflex.Dom

import WireTypes.Route (TaskLength(..))
import WireTypes.Pilot (Nyp(..), Dnf(..), DfNoTrack(..), Penal(..))
import FlareTiming.Events (IxTask(..))
import FlareTiming.Comms (getTaskPilotAbs)
import FlareTiming.Pilot (rowPilot, rowDfNt, rowPenal)
import WireTypes.Comp (UtcOffset(..))

tableAbsent
    :: MonadWidget t m
    => Dynamic t UtcOffset
    -> IxTask
    -> Dynamic t (Maybe TaskLength)
    -> Dynamic t Nyp
    -> Dynamic t Dnf
    -> Dynamic t DfNoTrack
    -> Dynamic t Penal
    -> m ()
tableAbsent utc ix ln nyp' dnf' dfNt' penal' = do
    pb <- getPostBuild
    let nyp = unNyp <$> nyp'
    let dnf = unDnf <$> dnf'
    let dfNt = unDfNoTrack <$> dfNt'
    let penal = unPenal <$> penal'
    abs <- holdDyn [] =<< getTaskPilotAbs ix pb

    elClass "div" "tile is-ancestor" $ do
        elClass "div" "tile is-vertical is-4" $
            elClass "div" "tile" $
                elClass "div" "tile is-parent is-vertical" $ do
                    dyn_ $ ffor abs (\abs'' ->
                        if null abs''
                            then
                                elClass "article" "tile is-child notification is-warning" $ do
                                    elClass "p" "title" $ text "ABS"
                                    elClass "p" "subtitle" $ text "absent"
                                    el "p" $ text "There are no ABS pilots"
                            else
                                elClass "article" "tile is-child box" $ do
                                    elClass "p" "title" $ text "ABS"
                                    elClass "p" "subtitle" $ text "absent"
                                    elClass "div" "content" $ do
                                        _ <- elClass "table" "table is-striped is-narrow" $ do
                                                el "thead" $ do
                                                    el "tr" $ do
                                                        el "th" $ text "Id"
                                                        el "th" $ text "Name"

                                                el "tbody" $ simpleList abs rowPilot

                                        el "p" . text
                                            $ "A pilot's absence does not reduce the task validity."
                        )

                    dyn_ $ ffor dnf (\dnf'' ->
                        if null dnf''
                            then
                                elClass "article" "tile is-child notification is-warning" $ do
                                    elClass "p" "title" $ text "DNF"
                                    elClass "p" "subtitle" $ text "did not fly"
                                    el "p" $ text "There are no DNF pilots"
                            else
                                elClass "article" "tile is-child box" $ do
                                    elClass "p" "title" $ text "DNF"
                                    elClass "p" "subtitle" $ text "did not fly"
                                    elClass "div" "content" $ do
                                        _ <- elClass "table" "table is-striped is-narrow" $ do
                                                el "thead" $ do
                                                    el "tr" $ do
                                                        el "th" $ text "Id"
                                                        el "th" $ text "Name"

                                                el "tbody" $ simpleList dnf rowPilot

                                        el "p" . text
                                            $ "Both launch validity and task validity are reduced when pilots elect not to fly. The reduction is made by taking the fraction of those not flying over those present at launch."
                        )

                    dyn_ $ ffor nyp (\nyp'' ->
                        if null nyp''
                            then
                                elClass "article" "tile is-child notification is-warning" $ do
                                    elClass "p" "title" $ text "NYP"
                                    elClass "p" "subtitle" $ text "not yet processed"
                                    el "p" $ text "There are no NYP pilots"
                            else
                                elClass "article" "tile is-child box" $ do
                                    elClass "p" "title" $ text "NYP"
                                    elClass "p" "subtitle" $ text "not yet processed"
                                    elClass "div" "content" $ do
                                        _ <- elClass "table" "table is-striped is-narrow" $ do
                                                el "thead" $ do
                                                    el "tr" $ do
                                                        el "th" $ text "Id"
                                                        el "th" $ text "Name"

                                                el "tbody" $ simpleList nyp rowPilot

                                        el "p" . text
                                            $ "Unlike DNF pilots, these pilots do not decrease launch validity. When a task is not at full distance validity, if any one of the NYP pilots flew further then the task validity will increase when they are processed. Likewise for time validity and the fastest pilots being NYP."
                        )

        elClass "div" "tile is-vertical is-8" $
            elClass "div" "tile" $
                elClass "div" "tile is-parent is-vertical" $ do
                    dyn_ $ ffor dfNt (\dfNt'' ->
                        if null dfNt''
                            then
                                elClass "article" "tile is-child notification is-warning" $ do
                                    elClass "p" "title" $ text "DF"
                                    elClass "p" "subtitle" $ text "no track"
                                    el "p" $ text "There are no DF-no-track pilots"
                            else
                                elClass "article" "tile is-child box" $ do
                                    elClass "p" "title" $ text "DF"
                                    elClass "p" "subtitle" $ text "no track"
                                    elClass "div" "content" $ do
                                        _ <- elClass "table" "table is-striped is-narrow" $ do
                                                el "thead" $ do
                                                    el "tr" $ do
                                                        el "th" $ text "Id"
                                                        el "th" $ text "Name"
                                                        elClass "th" "th-awarded-start" $ text "Start"
                                                        elClass "th" "th-awarded-end" $ text "End"
                                                        elClass "th" "th-awarded-reach" $ text "Reach"

                                                el "tbody" $ simpleList dfNt (rowDfNt utc ln)

                                        el "p" . text
                                            $ "These pilots get awarded at least minimum distance."
                        )

                    dyn_ $ ffor penal (\penal'' ->
                        if null penal''
                            then
                                elClass "article" "tile is-child notification is-warning" $ do
                                    elClass "p" "title" $ text "Penal"
                                    elClass "p" "subtitle" $ text "point adjustments"
                                    el "p" $ text "There are no penalties"
                            else
                                elClass "article" "tile is-child box" $ do
                                    elClass "p" "title" $ text "Penal"
                                    elClass "p" "subtitle" $ text "point adjustments"
                                    elClass "div" "content" $ do
                                        _ <- elClass "table" "table is-striped is-narrow" $ do
                                                el "thead" $ do
                                                    el "tr" $ do
                                                        el "th" $ text "Id"
                                                        el "th" $ text "Name"
                                                        elClass "th" "th-penalty" $ text "Fraction"
                                                        elClass "th" "th-penalty" $ text "Point"
                                                        elClass "th" "th-penalty-reason" $ text "Reason"

                                                el "tbody" $ simpleList penal rowPenal

                                        el "p" . text
                                            $ "These pilots were penalized or rewarded with a negative penalty."
                        )

    return ()