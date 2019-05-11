module FlareTiming.Task.Validity (viewValidity) where

import Prelude hiding (sum)
import Data.Maybe (fromMaybe)
import Reflex
import Reflex.Dom
import Data.String (IsString)
import Text.Printf (printf)
import qualified Data.Text as T (Text, pack)

import qualified WireTypes.Validity as Vy
    ( Validity(..)
    , showTaskValidity, showLaunchValidity, showDistanceValidity, showTimeValidity
    )
import WireTypes.ValidityWorking
    ( ValidityWorking(..)
    , LaunchValidityWorking(..)
    , DistanceValidityWorking(..)
    , TimeValidityWorking(..)
    , BestTime(..)
    )
import WireTypes.Route (TaskDistance(..), showTaskDistance)
import WireTypes.Reach (TrackReach(..), ReachStats(..))
import WireTypes.Point (showPilotDistance)
import WireTypes.Pilot (Pilot(..))
import FlareTiming.Pilot (showPilotName)

katexNewLine :: T.Text
katexNewLine = " \\\\\\\\ "

hookWorking :: Vy.Validity -> ValidityWorking -> ReachStats -> TaskDistance -> T.Text
hookWorking v ValidityWorking{launch = l, distance = d, time = t} r td =
    taskWorking v
    <> launchWorking v l
    <> distanceWorking v d
    <> timeWorking v t
    <> stopWorking v d t r td

taskWorking :: Vy.Validity -> T.Text
taskWorking v =
    "katex.render("
    <> "\"\\\\begin{aligned} "
    <> "validity &= lv * dv * tv"
    <> katexNewLine
    <> " &= "
    <> (Vy.showLaunchValidity . Vy.launch $ v)
    <> " * "
    <> (Vy.showDistanceValidity . Vy.distance $ v)
    <> " * "
    <> (Vy.showTimeValidity . Vy.time $ v)
    <> katexNewLine
    <> " &= "
    <> (Vy.showTaskValidity . Vy.task $ v)
    <> " \\\\end{aligned}\""
    <> ", getElementById('task-working')"
    <> ", {throwOnError: false});"

launchWorking :: Vy.Validity -> LaunchValidityWorking -> T.Text
launchWorking v w@LaunchValidityWorking{flying = f} =
    "katex.render("
    <> "\"\\\\begin{aligned} "
    <> "x &= \\\\min(1, \\\\frac{f}{p * n})"
    <> katexNewLine
    <> " &= \\\\min(1, \\\\frac{"
    <> (T.pack . show $ f)
    <> "}{"
    <> (T.pack . show $ present w)
    <> " * "
    <> (T.pack . show $ nominalLaunch w)
    <> "})"
    <> katexNewLine
    <> katexNewLine
    <> "validity &= 0.027 * x + 2.917 * x^2 - 1.944 * x^3"
    <> katexNewLine
    <> " &= "
    <> (Vy.showLaunchValidity . Vy.launch $ v)
    <> " \\\\end{aligned}\""
    <> ", getElementById('launch-working')"
    <> ", {throwOnError: false});"

distanceWorkingSubA :: DistanceValidityWorking -> T.Text
distanceWorkingSubA
    DistanceValidityWorking
        { nominalGoal = ng
        , nominalDistance = nd
        , minimumDistance = md
        } =
    " &= ("
    <> (T.pack . show $ ng)
    <> " + 1) * ("
    <> (T.pack . show $ nd)
    <> " - "
    <> (T.pack . show $ md)
    <> ")"

distanceWorkingSubB :: DistanceValidityWorking -> T.Text
distanceWorkingSubB
    DistanceValidityWorking
        { nominalGoal = ng
        , bestDistance = bd
        , nominalDistance = nd
        } =
    " &="
    <> " \\\\max(0, "
    <> (T.pack . show $ ng)
    <> " * ("
    <> (T.pack . show $ bd)
    <> " - "
    <> (T.pack . show $ nd)
    <> ")"

distanceWorking :: Vy.Validity -> DistanceValidityWorking -> T.Text
distanceWorking v w =
    "katex.render("
    <> "\"\\\\begin{aligned} "
    <> " sum"
    <> " &="
    <> " \\\\sum_p \\\\max(0, d_p - md)"
    <> " &\\\\"
    <> " d_p = \\\\text{distance flown by pilot \\\\textit{p}}"
    <> katexNewLine
    <> " &= "
    <> (T.pack . show $ sum w)
    <> katexNewLine
    <> katexNewLine
    <> " a &= (ng + 1) * (nd - md)"
    <> katexNewLine
    <> distanceWorkingSubA w
    <> katexNewLine
    <> katexNewLine
    <> " b &="
    <> " \\\\max(0, ng * (bd - nd)"
    <> katexNewLine
    <> distanceWorkingSubB w
    <> katexNewLine
    <> katexNewLine
    <> "area"
    <> " &="
    <> "\\\\frac{(a + b)}{2}"
    <> katexNewLine
    <> " &= "
    <> (T.pack . show $ area w)
    <> katexNewLine
    <> katexNewLine
    <> " validity &="
    <> " \\\\min(1, \\\\frac{sum}{f * area})"
    <> katexNewLine
    <> " &= "
    <> (Vy.showDistanceValidity . Vy.distance $ v)
    <> " \\\\end{aligned}\""
    <> ", getElementById('distance-working')"
    <> ", {throwOnError: false});"

timeWorkingCase :: (Semigroup p, IsString p) => Maybe a -> p
timeWorkingCase (Just _) = " &= \\\\dfrac{bt}{nt}"
timeWorkingCase Nothing = " &= \\\\dfrac{bd}{nd}"

timeWorkingSub :: TimeValidityWorking -> T.Text

timeWorkingSub
    TimeValidityWorking{gsBestTime = Just bt@(BestTime b), nominalTime = nt} =
    " &="
    <> " \\\\dfrac{"
    <> (T.pack . show $ bt)
    <> "}{"
    <> (T.pack . show $ nt)
    <> "}"
    <> katexNewLine
    <> " &="
    <> " \\\\dfrac{"
    <> (T.pack . printf "%f h" $ b)
    <> "}{"
    <> (T.pack . show $ nt)
    <> "}"

timeWorkingSub
    TimeValidityWorking{bestDistance = bd, nominalDistance = nd} =
    " &="
    <> " \\\\dfrac{"
    <> (T.pack . show $ bd)
    <> "}{"
    <> (T.pack . show $ nd)
    <> "}"

timeWorking :: Vy.Validity -> TimeValidityWorking -> T.Text
timeWorking v w@TimeValidityWorking{gsBestTime = bt} =
    "katex.render("
    <> "\"\\\\begin{aligned} "
    <> " x &="
    <> " \\\\begin{cases}"
    <> " \\\\dfrac{bt}{nt}"
    <> " &\\\\text{if at least one pilot reached ESS}"
    <> katexNewLine
    <> katexNewLine
    <> " \\\\dfrac{bd}{nd}"
    <> " &\\\\text{if no pilots reached ESS}"
    <> " \\\\end{cases}"
    <> katexNewLine
    <> timeWorkingCase bt
    <> katexNewLine
    <> timeWorkingSub w
    <> katexNewLine
    <> katexNewLine
    <> " y &= \\\\min(1, x)"
    <> katexNewLine
    <> katexNewLine
    <> " z &= -0.271 + 2.912 * y - 2.098 * y^2 + 0.457 * y^3"
    <> katexNewLine
    <> katexNewLine
    <> "validity &= \\\\max(0, \\\\min(1, z))"
    <> katexNewLine
    <> " &= "
    <> (Vy.showTimeValidity . Vy.time $ v)
    <> " \\\\end{aligned}\""
    <> ", getElementById('time-working')"
    <> ", {throwOnError: false});"


stopWorkingCase :: (Semigroup p, IsString p) => Maybe a -> p
stopWorkingCase (Just _) = " &= 1"
stopWorkingCase Nothing = " &= \\\\min(1, a + b^3)"

stopWorkingSubA :: DistanceValidityWorking -> ReachStats -> TaskDistance -> T.Text

stopWorkingSubA DistanceValidityWorking{..} ReachStats{..} td =
    " &= \\\\sqrt{\\\\frac{"
    <> bd
    <> " - "
    <> mr
    <> "}{"
    <> ed
    <> " - "
    <> bd
    <> " + 1} + \\\\sqrt{\\\\frac{"
    <> sr
    <> "}{5}}}"
    where
        bd = T.pack . show $ bestDistance
        ed = showTaskDistance td
        mr = showPilotDistance reachMean <> "km"
        sr = showPilotDistance reachStdDev <> "km"

stopWorkingSubB :: DistanceValidityWorking -> T.Text

stopWorkingSubB DistanceValidityWorking{..} =
    " &= \\\\frac{"
    <> ls
    <> "}{"
    <> f
    <> "}"
    where
        ls = "ls"
        f = T.pack . show $ flying

stopWorking
    :: Vy.Validity
    -> DistanceValidityWorking
    -> TimeValidityWorking
    -> ReachStats
    -> TaskDistance
    -> T.Text
stopWorking v dw TimeValidityWorking{gsBestTime = bt} reachStats td =
    "katex.render("
    <> "\"\\\\begin{aligned} "
    <> " a &= \\\\sqrt{\\\\frac{bd - \\\\overline{reach}}{ed - bd + 1} + \\\\sqrt{\\\\frac{\\\\sigma(reach)}{5}}}"
    <> katexNewLine
    <> stopWorkingSubA dw reachStats td
    <> katexNewLine
    <> katexNewLine
    <> " b &= \\\\frac{ls}{f}"
    <> katexNewLine
    <> stopWorkingSubB dw
    <> katexNewLine
    <> katexNewLine
    <> " validity &="
    <> " \\\\begin{cases}"
    <> " 1"
    <> " &\\\\text{if at least one pilot reached ESS}"
    <> katexNewLine
    <> katexNewLine
    <> " \\\\min(1, a + b^3)"
    <> " &\\\\text{if no pilots reached ESS}"
    <> " \\\\end{cases}"
    <> katexNewLine
    <> stopWorkingCase bt
    <> katexNewLine
    <> " &= "
    <> (Vy.showTimeValidity . Vy.time $ v)
    <> " \\\\end{aligned}\""
    <> ", getElementById('stop-working')"
    <> ", {throwOnError: false});"

spacer :: DomBuilder t m => m ()
spacer = elClass "div" "spacer" $ return ()

viewValidity
    :: MonadWidget t m
    => Dynamic t (Maybe Vy.Validity)
    -> Dynamic t (Maybe ValidityWorking)
    -> Dynamic t (Maybe ReachStats)
    -> Dynamic t (Maybe [(Pilot, TrackReach)])
    -> Dynamic t (Maybe TaskDistance)
    -> m ()
viewValidity vy vw reachStats reach td = do
    _ <- dyn $ ffor3 vy vw reachStats (\vy' vw' reachStats' ->
        dyn $ ffor td (\td' ->
            case (vy', vw', reachStats', td') of
                (Nothing, _, _, _) -> text "Loading validity ..."
                (_, Nothing, _, _) -> text "Loading validity workings ..."
                (_, _, Nothing, _) -> text "Loading reach stats ..."
                (_, _, _, Nothing) -> text "Loading stopped task distance ..."
                (Just v, Just w, Just r, Just d) -> do
                    elAttr
                        "a"
                        (("class" =: "button") <> ("onclick" =: hookWorking v w r d))
                        (text "Show Working")

                    spacer
                    viewDay v w
                    spacer
                    viewLaunch v w
                    spacer
                    viewDistance v w
                    spacer
                    viewTime v w
                    spacer
                    viewStop v w reachStats (fromMaybe [] <$> reach) d
                    spacer
                    return ()))

    return ()

viewDay
    :: DomBuilder t m
    => Vy.Validity
    -> ValidityWorking
    -> m ()
viewDay
    Vy.Validity{task, launch = lv, distance = dv, time = tv}
    ValidityWorking{launch = LaunchValidityWorking{..}} = do
    elClass "div" "card" $ do
        elClass "div" "card-content" $ do
            elClass "p" "level subtitle is-6" $ do
                elClass "span" "level-item level-left" $
                    elClass "h2" "title is-4" . text
                        $ "Task Validity* = " <> Vy.showTaskValidity task

                elClass "span" "level-item level-right" $
                    text "* Day Quality"

            elClass "div" "field is-grouped is-grouped-multiline" $ do
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "lv = launch validity"
                        elClass "span" "tag is-info" . text
                            $ Vy.showLaunchValidity lv
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "dv = distance validity"
                        elClass "span" "tag is-success" . text
                            $ Vy.showDistanceValidity dv
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "tv = time validity"
                        elClass "span" "tag is-primary" . text
                            $ Vy.showTimeValidity tv

            elAttr
                "div"
                ("id" =: "task-working")
                (text "")

    return ()

viewLaunch
    :: DomBuilder t m
    => Vy.Validity
    -> ValidityWorking
    -> m ()
viewLaunch
    Vy.Validity{launch = v}
    ValidityWorking{launch = LaunchValidityWorking{..}} = do
    elClass "div" "card" $ do
        elClass "div" "card-content" $ do
            elClass "h2" "title is-4" . text
                $ "Launch Validity = " <> Vy.showLaunchValidity v
            elClass "div" "field is-grouped is-grouped-multiline" $ do
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "f = pilots flying"
                        elClass "span" "tag is-info"
                            $ text (T.pack . show $ flying)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "p = pilots present"
                        elClass "span" "tag is-success"
                            $ text (T.pack . show $ present)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "n = nominal launch"
                        elClass "span" "tag is-primary"
                            $ text (T.pack . show $ nominalLaunch)

            elAttr
                "div"
                ("id" =: "launch-working")
                (text "")

    return ()

viewDistance
    :: DomBuilder t m
    => Vy.Validity
    -> ValidityWorking
    -> m ()
viewDistance
    Vy.Validity{distance = v}
    ValidityWorking{distance = DistanceValidityWorking{..}} = do
    elClass "div" "card" $ do
        elClass "div" "card-content" $ do
            elClass "h2" "title is-4" . text
                $ "Distance Validity = " <> Vy.showDistanceValidity v
            elClass "div" "field is-grouped is-grouped-multiline" $ do
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "f = pilots flying"
                        elClass "span" "tag is-info"
                            $ text (T.pack . show $ flying)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "area"
                        elClass "span" "tag is-success"
                            $ text (T.pack . show $ area)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "ng = nominal goal"
                        elClass "span" "tag is-primary"
                            $ text (T.pack . show $ nominalGoal)
            elClass "div" "field is-grouped is-grouped-multiline" $ do
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "sum = sum of distance"
                        elClass "span" "tag is-dark"
                            $ text (T.pack . show $ sum)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "nd = nominal distance"
                        elClass "span" "tag is-dark"
                            $ text (T.pack . show $ nominalDistance)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "md = minimum distance"
                        elClass "span" "tag is-dark"
                            $ text (T.pack . show $ minimumDistance)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "bd = best distance"
                        elClass "span" "tag is-dark"
                            $ text (T.pack . show $ bestDistance)

            elAttr
                "div"
                ("id" =: "distance-working")
                (text "")

    return ()

viewTime
    :: DomBuilder t m
    => Vy.Validity
    -> ValidityWorking
    -> m ()
viewTime
    Vy.Validity{time = v}
    ValidityWorking{time = TimeValidityWorking{..}} = do
    elClass "div" "card" $ do
        elClass "div" "card-content" $ do
            elClass "h2" "title is-4" . text
                $ "Time Validity = " <> Vy.showTimeValidity v
            elClass "div" "field is-grouped is-grouped-multiline" $ do
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "ss best time"
                        elClass "span" "tag is-info"
                            $ text (T.pack . show $ ssBestTime)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "bt = gs best time"
                        elClass "span" "tag is-success"
                            $ text (T.pack . show $ gsBestTime)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "nt = nominal time"
                        elClass "span" "tag is-primary"
                            $ text (T.pack . show $ nominalTime)
            elClass "div" "field is-grouped is-grouped-multiline" $ do
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "bd = best distance"
                        elClass "span" "tag is-dark"
                            $ text (T.pack . show $ bestDistance)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "nd = nominal distance"
                        elClass "span" "tag is-dark"
                            $ text (T.pack . show $ nominalDistance)

            elAttr
                "div"
                ("id" =: "time-working")
                (text "")

            elClass "div" "notification" $ do
                el "p" $ text "ss best time = the best time ignoring start gates"
                el "p" $ text "gs best time = the best time from the start gate taken"

    return ()

viewStop
    :: MonadWidget t m
    => Vy.Validity
    -> ValidityWorking
    -> Dynamic t (Maybe ReachStats)
    -> Dynamic t [(Pilot, TrackReach)]
    -> TaskDistance
    -> m ()
viewStop
    Vy.Validity{time = v}
    ValidityWorking
        { distance = DistanceValidityWorking{..}
        }
    reachStats
    reach
    td = do
    elClass "div" "card" $ do
        elClass "div" "card-content" $ do
            elClass "h2" "title is-4" . text
                $ "Stopped Task Validity = " <> Vy.showTimeValidity v
            elClass "div" "field is-grouped is-grouped-multiline" $ do
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "f = pilots flying"
                        elClass "span" "tag is-info"
                            $ text (T.pack . show $ flying)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "ls = pilots landed before stop time"
                        elClass "span" "tag is-warning"
                            $ text ""
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "bd = best distance"
                        elClass "span" "tag is-dark"
                            $ text (T.pack . show $ bestDistance)
                elClass "div" "control" $ do
                    elClass "div" "tags has-addons" $ do
                        elClass "span" "tag" $ do text "ed = launch to ESS distance"
                        elClass "span" "tag is-success" . text
                            $ showTaskDistance td
                _ <- dyn $ ffor reachStats (\case
                    Nothing -> return ()
                    Just ReachStats{..} ->
                        elClass "div" "field is-grouped is-grouped-multiline" $ do
                            elClass "div" "control" $ do
                                elClass "div" "tags has-addons" $ do
                                    elClass "span" "tag" $ do text "mean reach"
                                    elClass "span" "tag is-primary" . text
                                        $ showPilotDistance reachMean <> " km"
                            elClass "div" "control" $ do
                                elClass "div" "tags has-addons" $ do
                                    elClass "span" "tag" $ do text "reach standard deviation"
                                    elClass "span" "tag is-primary" . text
                                        $ showPilotDistance reachStdDev <> " km")

                return ()

            spacer

            elAttr
                "div"
                ("id" =: "stop-working")
                (text "")

            elClass "div" "tile is-child" $ tablePilotReach reach
    return ()

tablePilotReach
    :: MonadWidget t m
    => Dynamic t [(Pilot, TrackReach)]
    -> m ()
tablePilotReach xs = do
    _ <- elClass "table" "table is-striped" $ do
            el "thead" $ do
                el "tr" $ do
                    elClass "th" "th-plot-reach" $ text "Reach (km)"
                    el "th" $ text "Pilot"

                    return ()

            el "tbody" $ do
                simpleList xs (uncurry rowReach . splitDynPure)

    return ()

rowReach
    :: MonadWidget t m
    => Dynamic t Pilot
    -> Dynamic t TrackReach
    -> m ()
rowReach p tm = do
    el "tr" $ do
        elClass "td" "td-plot-reach" . dynText $ showPilotDistance . reach <$> tm
        el "td" . dynText $ showPilotName <$> p

        return ()
