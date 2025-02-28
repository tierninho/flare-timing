module FlareTiming.Task.Score.Time (tableScoreTime) where

import Prelude hiding (min)
import Reflex.Dom
import Data.List (sortBy)
import Data.Maybe (fromMaybe)
import qualified Data.Text as T (pack)
import qualified Data.Map.Strict as Map

import WireTypes.Route (TaskLength(..))
import qualified WireTypes.Point as Norm (NormBreakdown(..))
import qualified WireTypes.Point as Pt (Points(..))
import qualified WireTypes.Point as Wg (Weights(..))
import qualified WireTypes.Validity as Vy (Validity(..))
import WireTypes.Point
    ( TaskPlacing(..), TaskPoints(..), Breakdown(..), Velocity(..), StartGate(..)
    , Points(..)
    , showTimePoints, showTimePointsDiff, showTaskTimePoints
    , cmpTime
    )
import WireTypes.ValidityWorking (ValidityWorking(..), TimeValidityWorking(..))
import WireTypes.Comp (UtcOffset(..), Discipline(..), MinimumDistance(..))
import WireTypes.Pilot (Pilot(..), Dnf(..), DfNoTrack(..))
import qualified WireTypes.Pilot as Pilot (DfNoTrackPilot(..))
import FlareTiming.Pilot (showPilot)
import FlareTiming.Task.Score.Show

tableScoreTime
    :: MonadWidget t m
    => Dynamic t UtcOffset
    -> Dynamic t Discipline
    -> Dynamic t MinimumDistance
    -> Dynamic t [StartGate]
    -> Dynamic t (Maybe TaskLength)
    -> Dynamic t Dnf
    -> Dynamic t DfNoTrack
    -> Dynamic t (Maybe Vy.Validity)
    -> Dynamic t (Maybe ValidityWorking)
    -> Dynamic t (Maybe Wg.Weights)
    -> Dynamic t (Maybe Pt.Points)
    -> Dynamic t (Maybe TaskPoints)
    -> Dynamic t [(Pilot, Breakdown)]
    -> Dynamic t [(Pilot, Norm.NormBreakdown)]
    -> m ()
tableScoreTime _utcOffset hgOrPg _free sgs _ln dnf' dfNt _vy vw _wg pt _tp sDfs sEx = do
    let dnf = unDnf <$> dnf'
    lenDnf :: Int <- sample . current $ length <$> dnf
    lenDfs :: Int <- sample . current $ length <$> sDfs
    let dnfPlacing =
            (if lenDnf == 1 then TaskPlacing else TaskPlacingEqual)
            . fromIntegral
            $ lenDfs + 1

    let tableClass =
            let tc = "table is-striped is-narrow is-fullwidth" in
            ffor2 hgOrPg sgs (\x gs ->
                let y = T.pack . show $ x in
                y <> (if null gs then " " else " sg ") <> tc)

    _ <- elDynClass "table" tableClass $ do
        el "thead" $ do

            el "tr" $ do
                elAttr "th" ("colspan" =: "6") $ text ""
                elAttr "th" ("colspan" =: "3" <> "class" =: "th-time-points-breakdown") $ text "Points for Time (Descending)"

            el "tr" $ do
                elClass "th" "th-placing" $ text "Place"
                elClass "th" "th-pilot" $ text "###-Pilot"

                elClass "th" "th-time" $ text "Time †"

                elClass "th" "th-norm th-time" . dynText
                    $ ffor sgs (\case [] -> "✓-Pace"; _ -> "✓-Time")

                elClass "th" "th-norm th-time-diff" $ dynText
                    $ ffor sgs (\case [] -> "Δ-Pace"; _ -> "Δ-Time")

                elClass "th" "th-pace" $ text "Pace ‡"

                elClass "th" "th-time-points" $ text "Time"
                elClass "th" "th-norm th-time-points" $ text "✓"
                elClass "th" "th-norm th-diff" $ text "Δ"

        _ <- el "tbody" $ do
            _ <-
                simpleList
                    (sortBy cmpTime <$> sDfs)
                    (pointRow
                        dfNt
                        pt
                        (Map.fromList <$> sEx))

            dnfRows dnfPlacing dnf'
            return ()

        let tdFoot = elAttr "td" ("colspan" =: "16")
        let foot = el "tr" . tdFoot . text

        el "tfoot" $ do
            foot "† \"Time\" is the time across the speed section from time zero of the start gate taken."
            foot "‡ \"Pace\" is the time across the speed section from the time of crossing the start for the last time."
            foot "☞ Pilots without a tracklog but given a distance by the scorer."
            foot "✓ An expected value as calculated by the official scoring program, FS."
            foot "Δ A difference between a value and an expected value."
            dyn_ $ ffor hgOrPg (\case
                HangGliding -> return ()
                Paragliding -> do
                    el "tr" . tdFoot $ do
                            elClass "span" "pg not" $ text "Arrival"
                            text " points are not scored for paragliding."
                    el "tr" . tdFoot $ do
                            elClass "span" "pg not" $ text "Effort"
                            text " or distance difficulty is not scored for paragliding.")
            dyn_ $ ffor sgs (\gs ->
                if null gs then do
                    el "tr" . tdFoot $ do
                            text "With no "
                            elClass "span" "sg not" $ text "gate"
                            text " to start the speed section "
                            elClass "span" "sg not" $ text "time"
                            text ", the pace clock starts ticking whenever the pilot starts."
                else return ())
            dyn_ $ ffor hgOrPg (\case
                HangGliding ->
                    dyn_ $ ffor vw (\vw' ->
                        maybe
                            (return ())
                            (\ValidityWorking{time = TimeValidityWorking{..}} ->
                                case gsBestTime of
                                    Just _ -> return ()
                                    Nothing -> el "tr" . tdFoot $ do
                                        text "No one made it through the speed section to get "
                                        elClass "span" "gr-zero" $ text "time"
                                        text " and "
                                        elClass "span" "gr-zero" $ text "arrival"
                                        text " points.")
                            vw'
                        )
                Paragliding -> 
                    dyn_ $ ffor vw (\vw' ->
                        maybe
                            (return ())
                            (\ValidityWorking{time = TimeValidityWorking{..}} ->
                                case gsBestTime of
                                    Just _ -> return ()
                                    Nothing -> el "tr" . tdFoot $ do
                                        text "No one made it through the speed section to get "
                                        elClass "span" "gr-zero" $ text "time"
                                        text " points.")
                            vw'
                        ))

    return ()

pointRow
    :: MonadWidget t m
    => Dynamic t DfNoTrack
    -> Dynamic t (Maybe Pt.Points)
    -> Dynamic t (Map.Map Pilot Norm.NormBreakdown)
    -> Dynamic t (Pilot, Breakdown)
    -> m ()
pointRow dfNt pt sEx x = do
    let pilot = fst <$> x
    let xB = snd <$> x
    let v = velocity . snd <$> x
    let points = breakdown <$> xB

    let classPilot = ffor2 pilot dfNt (\p (DfNoTrack ps) ->
                        let n = showPilot p in
                        if p `elem` (Pilot.pilot <$> ps)
                           then ("pilot-dfnt", n <> " ☞ ")
                           else ("", n))

    (yEl, yElDiff, tPts, tPtsDiff) <- sample . current
                $ ffor3 pilot sEx x (\pilot' sEx' (_, Breakdown
                                                          { velocity = v'
                                                          , breakdown =
                                                              Points{time = tPts}
                                                          }) ->
                fromMaybe ("", "", "", "") $ do
                    Velocity
                        { ss
                        , gs
                        , gsElapsed = gsElap
                        , ssElapsed = ssElap
                        } <- v'

                    Norm.NormBreakdown
                        { timeElapsed = elap'
                        , breakdown = Points{time = tPtsN}
                        } <- Map.lookup pilot' sEx'

                    let elap =
                            case (ss, gs) of
                                (_, Just _) -> gsElap
                                (Just _, _) -> ssElap
                                _ -> Nothing

                    return
                        ( maybe "" showPilotTime elap'
                        , fromMaybe "" (showPilotTimeDiff <$> elap' <*> elap)
                        , showTimePoints tPtsN
                        , showTimePointsDiff tPtsN tPts
                        ))

    elDynClass "tr" (fst <$> classPilot) $ do
        elClass "td" "td-placing" . dynText $ showRank . place <$> xB
        elClass "td" "td-pilot" . dynText $ snd <$> classPilot

        elClass "td" "td-time" . dynText $ maybe "" showGsVelocityTime <$> v
        elClass "td" "td-norm td-time" . text $ yEl
        elClass "td" "td-norm td-time-diff" . text $ yElDiff

        elClass "td" "td-pace" . dynText $ maybe "" showSsVelocityTime <$> v

        elClass "td" "td-effort-points" . dynText
            $ showMax Pt.time showTaskTimePoints pt points
        elClass "td" "td-norm td-arrival-points" . text $ tPts
        elClass "td" "td-norm td-arrival-points" . text $ tPtsDiff

dnfRows
    :: MonadWidget t m
    => TaskPlacing
    -> Dynamic t Dnf
    -> m ()
dnfRows place ps' = do
    let ps = unDnf <$> ps'
    len <- sample . current $ length <$> ps
    let p1 = take 1 <$> ps
    let pN = drop 1 <$> ps

    case len of
        0 -> do
            return ()
        1 -> do
            _ <- simpleList ps (dnfRow place (Just 1))
            return ()
        n -> do
            _ <- simpleList p1 (dnfRow place (Just n))
            _ <- simpleList pN (dnfRow place Nothing)
            return ()

dnfRow
    :: MonadWidget t m
    => TaskPlacing
    -> Maybe Int
    -> Dynamic t Pilot
    -> m ()
dnfRow place rows pilot = do
    let dnfMega =
            case rows of
                Nothing -> return ()
                Just n -> do
                    elAttr
                        "td"
                        ( "rowspan" =: (T.pack $ show n)
                        <> "colspan" =: "7"
                        <> "class" =: "td-dnf"
                        )
                        $ text "DNF"
                    return ()

    elClass "tr" "tr-dnf" $ do
        elClass "td" "td-placing" . text $ showRank place
        elClass "td" "td-pilot" . dynText $ showPilot <$> pilot
        dnfMega
        return ()
