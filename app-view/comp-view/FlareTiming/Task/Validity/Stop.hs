module FlareTiming.Task.Validity.Stop
    ( viewStop
    , stopWorking
    ) where

import Prelude hiding (max, sum)
import qualified Prelude as Stats (max, sum)
import Data.Time.Clock (UTCTime)
import Data.Time.LocalTime (TimeZone)
import Reflex
import Reflex.Dom
import Text.Printf (printf)
import qualified Data.Text as T (Text, pack)
import Data.Map (Map)
import qualified Data.Map.Strict as Map

import qualified WireTypes.Validity as Vy (Validity(..), showStopValidity)
import WireTypes.ValidityWorking
    ( ValidityWorking(..)
    , DistanceValidityWorking(..)
    , TimeValidityWorking(..)
    , ReachStats(..)
    , PilotsFlying(..)
    , MaximumDistance(..)
    )
import WireTypes.Cross (FlyingSection)
import WireTypes.Route (TaskDistance(..), showTaskDistance)
import WireTypes.Reach (TrackReach(..))
import qualified WireTypes.Reach as Stats (BolsterStats(..))
import WireTypes.Point (PilotDistance(..), showPilotDistance)
import WireTypes.Pilot (Pilot(..))
import WireTypes.Comp (UtcOffset(..), MinimumDistance(..))
import FlareTiming.Pilot (showPilotName)
import FlareTiming.Time (timeZone, showTime)
import qualified FlareTiming.Statistics as Stats (mean, stdDev)
import FlareTiming.Task.Validity.Widget (katexNewLine)
import FlareTiming.Task.Validity.Stop.Counts (viewStopCounts)
import FlareTiming.Task.Validity.Stop.Max (viewStopMax)
import FlareTiming.Task.Validity.Stop.Mean (viewStopMean)
import FlareTiming.Task.Validity.Stop.StdDev (viewStopStdDev)

stopWorkingCase :: Maybe a -> Double -> Double -> (Double, T.Text)
stopWorkingCase (Just _) _ _ = (1, " &= 1")
stopWorkingCase Nothing a b = (min 1 (a + b3), eqn) where
        eqn =
            " &= \\\\min(1, a + b^3)"
            <> katexNewLine
            <> " &= \\\\min(1, " <> a' <> " + " <> b' <> ")"

        b3 = b**3
        b' = T.pack $ printf "%.3f" b3
        a' = T.pack $ printf "%.3f" a

stopWorkingSubA
    :: DistanceValidityWorking
    -> Stats.BolsterStats
    -> TaskDistance
    -> (Double, T.Text)

stopWorkingSubA
    DistanceValidityWorking{bestDistance = bd@(MaximumDistance bd')}
    Stats.BolsterStats
        { bolster =
            ReachStats
                { mean = mf@(PilotDistance mf')
                , stdDev = sf@(PilotDistance sf')
                }
        }
    td@(TaskDistance td') = (z, eqn) where
        eqn =
            " &= \\\\sqrt{\\\\frac{"
            <> bd''
            <> " - "
            <> mf''
            <> "}{"
            <> ed
            <> " - "
            <> bd''
            <> " + 1} * \\\\sqrt{\\\\frac{"
            <> sf''
            <> "}{5}}}"
            <> katexNewLine
            <> " &= \\\\sqrt{\\\\frac{"
            <> textf (bd' - mf')
            <> "}{"
            <> textf (td' - bd' + 1)
            <> "} * \\\\sqrt{"
            <> textf (sf' / 5)
            <> "}}"
            <> katexNewLine
            <> " &= \\\\sqrt{"
            <> x'
            <> " * "
            <> y'
            <> "}"
            <> katexNewLine
            <> (" &= " <> z')

        bd'' = T.pack $ show bd
        ed = showTaskDistance td
        mf'' = showPilotDistance 3 mf <> "km"
        sf'' = showPilotDistance 3 sf <> "km"

        textf = T.pack . printf "%.3f"
        x' = textf x
        y' = textf y
        z' = textf z

        x = (bd' - mf') / (td' - bd' + 1)
        y = sqrt $ sf' / 5
        z = sqrt $ x * y

stopWorkingSubB :: DistanceValidityWorking -> Int -> Double -> T.Text

stopWorkingSubB DistanceValidityWorking{flying = PilotsFlying pf} landed b' =
    " &= \\\\frac{"
    <> ls
    <> "}{"
    <> f
    <> "}"
    <> katexNewLine
    <> (" &= " <> b)
    where
        ls = T.pack . show $ landed
        f = T.pack . show $ pf
        b = T.pack $ printf "%.3f" b'

stopWorking
    :: DistanceValidityWorking
    -> TimeValidityWorking
    -> Stats.BolsterStats
    -> TaskDistance
    -> Int
    -> T.Text
stopWorking
    dw@DistanceValidityWorking{flying = PilotsFlying pf}
    TimeValidityWorking{gsBestTime = bt}
    reachStats
    td
    landed =

    "katex.render("
    <> "\"\\\\begin{aligned} "
    <> " bd &= \\\\max(flown)"
    <> katexNewLine
    <> katexNewLine
    <> " a &= \\\\sqrt{\\\\frac{bd - \\\\mu(flown)}{ed - bd + 1} * \\\\sqrt{\\\\frac{\\\\sigma(flown)}{5}}}"
    <> katexNewLine
    <> eqnA
    <> katexNewLine
    <> katexNewLine
    <> " b &= \\\\frac{ls}{f}"
    <> katexNewLine
    <> stopWorkingSubB dw landed b
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
    <> eqnV
    <> katexNewLine
    <> (" &= " <> (T.pack $ printf "%.3f" v))
    <> " \\\\end{aligned}\""
    <> ", getElementById('stop-working')"
    <> ", {throwOnError: false});"
    where
        b = fromIntegral landed / (fromIntegral pf :: Double)
        (a, eqnA) = stopWorkingSubA dw reachStats td
        (v, eqnV) = stopWorkingCase bt a b

viewStop
    :: MonadWidget t m
    => Dynamic t UtcOffset
    -> Dynamic t MinimumDistance
    -> Vy.Validity
    -> Vy.Validity
    -> ValidityWorking
    -> ValidityWorking
    -> Stats.BolsterStats
    -> Stats.BolsterStats
    -> Dynamic t [(Pilot, TrackReach)]
    -> Dynamic t [(Pilot, TrackReach)]
    -> Dynamic t [(Pilot, FlyingSection UTCTime)]
    -> Dynamic t [(Pilot, FlyingSection UTCTime)]
    -> m ()
viewStop _ _ Vy.Validity{stop = Nothing} _ _ _ _ _ _ _ _ _ = return ()
viewStop _ _ _ Vy.Validity{stop = Nothing} _ _ _ _ _ _ _ _ = return ()
viewStop _ _ _ _ ValidityWorking{stop = Nothing} _ _ _ _ _ _ _ = return ()
viewStop _ _ _ _ _ ValidityWorking{stop = Nothing} _ _ _ _ _ _ = return ()
viewStop
    utcOffset
    free
    v@Vy.Validity{stop = sv}
    vN
    -- | Working from flare-timing.
    vw
    -- | Working from FS, normal or expected.
    vwN
    -- | Reach as flown.
    sf
    -- | With extra altitude converted by way of glide to extra reach.
    se
    reach
    bonusReach
    landedByStop
    stillFlying = do

    elClass "div" "card" $ do
        elClass "div" "card-content" $ do
            elClass "h2" "title is-4" $ do
                elClass "span" "legend-stop" $ text "▩"
                text $ " Stop Validity = " <> Vy.showStopValidity sv

            elClass "div" "tile is-ancestor" $ do
                elClass "div" "tile is-12" $
                    elClass "div" "tile" $ do
                        elClass "div" "tile is-parent" $ do
                            elClass "article" "tile is-child box" $ do
                                elClass "p" "title" $ text "Landed"
                                elClass "p" "subtitle" $ text "landed before stop"
                                elClass "div" "content"
                                    $ tablePilotFlyingTimes utcOffset landedByStop

                        elClass "div" "tile is-parent" $ do
                            elClass "article" "tile is-child box" $ do
                                elClass "p" "title" $ text "Flying"
                                elClass "p" "subtitle" $ text "still flying at stop"
                                elClass "div" "content"
                                    $ tablePilotFlyingTimes utcOffset stillFlying

            elClass "div" "tile is-ancestor" $ do
                elClass "div" "tile is-12" $
                    elClass "div" "tile" $
                        elClass "div" "tile is-parent" $
                            elClass "article" "tile is-child box" $ do
                                elClass "p" "title" $ text "Reach"
                                elClass "p" "subtitle" $ text "best distance reached at or before stop"
                                elClass "div" "content"
                                    $ tablePilotReach free reach bonusReach

            elClass "div" "tile is-ancestor" $ do
                elClass "div" "tile is-12" $
                    elClass "div" "tile" $ do
                        elClass "div" "tile is-parent" $ do
                            elClass "article" "tile is-child box" $ do
                                elClass "p" "title" $ text "max"
                                elClass "p" "subtitle" $ text "maximum km"
                                elClass "div" "content" $
                                    viewStopMax vw vwN sf se

                        elClass "div" "tile is-parent" $ do
                            elClass "article" "tile is-child box" $ do
                                elClass "p" "title" $ text "μ"
                                elClass "p" "subtitle" $ text "mean km"
                                elClass "div" "content" $
                                    viewStopMean vw vwN sf se

                        elClass "div" "tile is-parent" $ do
                            elClass "article" "tile is-child box" $ do
                                elClass "p" "title" $ text "σ"
                                elClass "p" "subtitle" $ text "standard deviation km"
                                elClass "div" "content" $
                                    viewStopStdDev vw vwN sf se

            elClass "div" "tile is-ancestor" $ do
                elClass "div" "tile is-12" $
                    elClass "div" "tile" $
                        elClass "div" "tile is-parent" $ do
                            elClass "article" "tile is-child box" $ do
                                elClass "p" "title" $ text "Pilots, Distance & Validity"
                                elClass "p" "subtitle" $ text "other stop validity formula inputs and the stop validity itself"
                                elClass "div" "content" $
                                    viewStopCounts v vN vw vwN

            elAttr
                "div"
                ("id" =: "stop-working")
                (text "")

    return ()

tablePilotFlyingTimes
    :: MonadWidget t m
    => Dynamic t UtcOffset
    -> Dynamic t [(Pilot, FlyingSection UTCTime)]
    -> m ()
tablePilotFlyingTimes utcOffset xs = do
    tz <- sample . current $ timeZone <$> utcOffset
    _ <- elClass "table" "table is-striped" $ do
            el "thead" $ do
                el "tr" $ do
                    el "th" $ text "Landed"
                    el "th" $ text "Pilot"

                    return ()

            el "tbody" $ do
                simpleList xs (uncurry (rowFlyingTimes tz) . splitDynPure)

    return ()

rowFlyingTimes
    :: MonadWidget t m
    => TimeZone
    -> Dynamic t Pilot
    -> Dynamic t (FlyingSection UTCTime)
    -> m ()
rowFlyingTimes tz p tm = do
    let t = maybe "-" (T.pack . showTime tz . snd) <$> tm
    el "tr" $ do
        el "td" $ dynText t
        el "td" . dynText $ showPilotName <$> p

        return ()

tablePilotReach
    :: MonadWidget t m
    => Dynamic t MinimumDistance
    -> Dynamic t [(Pilot, TrackReach)]
    -> Dynamic t [(Pilot, TrackReach)]
    -> m ()
tablePilotReach free reach bonusReach = do
    let tdFoot = elAttr "td" ("colspan" =: "8")
    let foot = el "tr" . tdFoot . text

    _ <- elClass "table" "table is-striped" $ do
            el "thead" $ do
                el "tr" $ do
                    el "th" $ text ""
                    elAttr "th" (("colspan" =: "3") <> ("class" =: "th-valid-reach-col")) $ text "Reach (km)"
                    elAttr "th" (("colspan" =: "3") <> ("class" =: "th-valid-bolster-col"))$ text "Bolster (km)"
                    el "th" $ text ""

                    return ()

            el "thead" $ do
                el "tr" $ do
                    el "th" $ text ""

                    elClass "th" "th-valid-reach" $ text "Flown †"
                    elClass "th" "th-valid-reach-extra" $ text "Extra ‡"
                    elClass "th" "th-valid-reach-extra-diff" $ text "Δ"

                    elClass "th" "th-valid-bolster" $ text "Flown"
                    elClass "th" "th-valid-bolster-extra" $ text "Extra"
                    elClass "th" "th-valid-bolster-extra-diff" $ text "Δ"

                    el "th" $ text "Pilot"

                    return ()

            _ <- el "tbody" . dyn $ ffor3 free reach bonusReach (\free'@(MinimumDistance dMin) r br -> do

                    let rs = [d | (_, TrackReach{reach = PilotDistance d}) <- r]
                    let rs' = Stats.max dMin <$> rs

                    let bs = [d | (_, TrackReach{reach = PilotDistance d}) <- br]
                    let bs' = Stats.max dMin <$> bs

                    let ds = zipWith (-) bs rs
                    let ds' = zipWith (-) bs' rs'

                    let mapR = Map.fromList br

                    _ <- simpleList reach (uncurry (rowReachBonus free' mapR) . splitDynPure)
                    let f = text . T.pack . printf "%.3f"

                    el "tr" $ do
                        el "th" $ text "∑"
                        elClass "td" "td-valid-reach" . f
                            $ Stats.sum rs
                        elClass "td" "td-valid-reach-extra" . f
                            $ Stats.sum bs
                        elClass "td" "td-valid-reach-extra-diff" . f
                            $ Stats.sum ds

                        elClass "td" "td-valid-bolster" . f
                            $ Stats.sum rs'
                        elClass "td" "td-valid-bolster-extra" . f
                            $ Stats.sum bs'
                        elClass "td" "td-valid-bolster-extra-diff" . f
                            $ Stats.sum ds'
                        elAttr "td" ("rowspan" =: "4") $ text ""

                        return ()

                    el "tr" $ do
                        el "th" $ text "max"
                        elClass "td" "td-valid-reach" . f
                            $ maximum rs
                        elClass "td" "td-valid-reach-extra" . f
                            $ maximum bs
                        elClass "td" "td-valid-reach-extra-diff" . f
                            $ maximum ds

                        elClass "td" "td-valid-bolster" . f
                            $ maximum rs'
                        elClass "td" "td-valid-bolster-extra" . f
                            $ maximum bs'
                        elClass "td" "td-valid-bolster-extra-diff" . f
                            $ maximum ds'

                        return ()

                    el "tr" $ do
                        el "th" $ text "μ"
                        elClass "td" "td-valid-reach" . f
                            $ Stats.mean rs
                        elClass "td" "td-valid-reach-extra" . f
                            $ Stats.mean bs
                        elClass "td" "td-valid-reach-extra-diff" . f
                            $ Stats.mean ds

                        elClass "td" "td-valid-bolster" . f
                            $ Stats.mean rs'
                        elClass "td" "td-valid-bolster-extra" . f
                            $ Stats.mean bs'
                        elClass "td" "td-valid-bolster-extra-diff" . f
                            $ Stats.mean ds'

                        return ()

                    el "tr" $ do
                        el "th" $ text "σ"
                        elClass "td" "td-valid-reach" . f
                            $ Stats.stdDev rs
                        elClass "td" "td-valid-reach-extra" . f
                            $ Stats.stdDev bs
                        elClass "td" "td-valid-reach-extra-diff" . f
                            $ Stats.stdDev ds

                        elClass "td" "td-valid-bolster" . f
                            $ Stats.stdDev rs'
                        elClass "td" "td-valid-bolster-extra" . f
                            $ Stats.stdDev bs'
                        elClass "td" "td-valid-bolster-extra-diff" . f
                            $ Stats.stdDev ds'

                        return ()
                    return ())

            el "tfoot" $ do
                foot "† With reach clamped below to be no smaller than minimum distance."
                foot "‡ As scored with altitude above goal converted to extra reach via glide."
                foot "Δ Altitude bonus reach."
            return ()
    return ()

rowReachBonus
    :: MonadWidget t m
    => MinimumDistance
    -> Map Pilot TrackReach
    -> Dynamic t Pilot
    -> Dynamic t TrackReach
    -> m ()
rowReachBonus (MinimumDistance dMin) mapR p r = do
    (reachF, bolsterF, reachE', bolsterE', reachDiff, bolsterDiff) <- sample . current
            $ ffor2 p r (\p' r' ->
                case Map.lookup p' mapR of
                    Just br ->
                        let reachE@(PilotDistance dE) = reach br
                            reachF@(PilotDistance dF) = reach r'

                            bolsterE = PilotDistance $ Stats.max dE dMin
                            bolsterF = PilotDistance $ Stats.max dF dMin
                        in
                            ( showPilotDistance 3 $ reachF
                            , showPilotDistance 3 $ bolsterF
                            , showPilotDistance 3 $ reachE
                            , showPilotDistance 3 $ bolsterE
                            , showPilotDistanceDiff reachF reachE
                            , showPilotDistanceDiff bolsterF bolsterE
                            )

                    _ -> ("", "", "", "", "", ""))

    el "tr" $ do
        el "td" $ text ""

        elClass "td" "td-valid-reach" $ text reachF
        elClass "td" "td-valid-reach-extra" $ text reachE'
        elClass "td" "td-valid-reach-extra-diff" $ text reachDiff

        elClass "td" "td-valid-bolster" $ text bolsterF
        elClass "td" "td-valid-bolster-extra" $ text bolsterE'
        elClass "td" "td-valid-bolster-extra-diff" $ text bolsterDiff

        el "td" . dynText $ showPilotName <$> p

        return ()

showPilotDistanceDiff :: PilotDistance -> PilotDistance -> T.Text
showPilotDistanceDiff (PilotDistance expected) (PilotDistance actual)
    | printf "%.3f" actual == (printf "%.3f" expected :: String) = "="
    | otherwise = T.pack . printf "%+.3f" $ actual - expected
