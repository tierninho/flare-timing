module FlareTiming.Map.View (viewMap) where

-- TODO: Find out why hiding Debug.Trace.debugEvent doesn't work.
-- Ambiguous occurrence ‘traceEvent’
-- It could refer to either ‘Debug.Trace.traceEvent’,
--                           imported from ‘Debug.Trace’ at ...
--                           or ‘Reflex.Dom.traceEvent’,
--                           imported from ‘Reflex.Dom’ at ...
--                           (and originally defined in ‘Reflex.Class’)
-- import Debug.Trace hiding (debugEvent)
-- import Reflex.Dom
-- import qualified Debug.Trace as DT
import Prelude hiding (map)
import Text.Printf (printf)
import Reflex.Dom
import Data.Time.LocalTime (TimeZone)

import qualified Data.Text as T (Text, pack)
import Reflex.Time (delay)
import Data.Maybe (catMaybes, listToMaybe)
import Data.List (zipWith4)
import qualified Data.Map as Map
import Control.Monad (sequence)
import Control.Monad.IO.Class (liftIO)

import qualified FlareTiming.Map.Leaflet as L
    ( Marker(..)
    , Circle(..)
    , Semicircle(..)
    , map
    , mapSetView
    , layerGroup
    , layerGroupAddToMap
    , tileLayer
    , tileLayerAddToMap
    , marker
    , markerPopup
    , mapInvalidateSize
    , circle
    , circleAddToMap
    , semicircle
    , semicircleAddToMap
    , trackLine
    , discardLine
    , routeLine
    , fitBounds
    , panToBounds
    , latLngBounds
    , layersControl
    , layersExpand
    , addOverlay
    )
import WireTypes.Cross
    ( TrackFlyingSection(..)
    , TrackScoredSection(..)
    , Fix(..), InterpolatedFix(..)
    , ZoneCross(..), ZoneTag(..)
    )
import WireTypes.Pilot (Pilot(..), PilotName(..), getPilotName, nullPilot)
import WireTypes.Comp
    ( UtcOffset(..), Task(..), SpeedSection
    , getGoalShape, getAllRawZones
    )
import WireTypes.Zone
    (Zones(..), RawZone(..), RawLatLng(..), RawLat(..), RawLng(..))
import WireTypes.ZoneKind (Radius(..), Shape(..))
import WireTypes.Route
    ( OptimalRoute, TrackLine
    , TaskRoute(..), TaskRouteSubset(..), SpeedRoute(..)
    , optimalTaskRoute, lineToRoute
    , optimalTaskRoute, optimalTaskRouteSubset, optimalSpeedRoute
    )
import qualified FlareTiming.Turnpoint as TP (getName)
import FlareTiming.Comms (getTaskPilotDf)
import FlareTiming.Events (IxTask(..))
import FlareTiming.Time (timeZone, showTime)
import FlareTiming.Earth (AzimuthFwd(..), azimuthFwd, azimuthFlip)

data ZoomOrPan = Zoom | Pan deriving Show

zoomButton
    :: MonadWidget t m
    => (RawZone, T.Text)
    -> m (Event t [RawZone])
zoomButton (z, btnClass) = do
    let s = TP.getName z
    (e, _) <- elClass' "a" btnClass $ text s
    return $ [z] <$ domEvent Click e

zoomOrPanIcon :: ZoomOrPan -> T.Text
zoomOrPanIcon Zoom = "fa fa-search-plus"
zoomOrPanIcon Pan = "fa fa-arrows"

pilotToSelectMap :: [Pilot] -> Map.Map Int T.Text
pilotToSelectMap ps =
    Map.fromList
    $ (0, "Select a pilot")
    : zipWith (\i (Pilot (_, PilotName n)) -> (i, T.pack n)) [1..] ps

pilotAtIdx :: Int -> [Pilot] -> Maybe Pilot
pilotAtIdx 0 _ = Nothing
pilotAtIdx ii ps =
    -- WARNING: The zeroth item is the prompt in the select.
    listToMaybe . take 1 . drop (ii - 1) $ ps

taskZoneButtons
    :: MonadWidget t m
    => Task
    -> Dynamic t [Pilot]
    -> Event t ()
    -> m (Dynamic t ZoomOrPan, Dynamic t [RawZone], Event t Pilot)
taskZoneButtons t@Task{speedSection} ps eDownloaded = do
    let ps' = pilotToSelectMap <$> ps
    let zones = getAllRawZones t
    let btn = "button"
    let btnStart = "button has-text-success"
    let btnEnd = "button has-text-danger"

    let zoneClasses =
            maybe
                (zip zones $ repeat btn)
                (\(start, end) ->
                    zipWith
                        (\z i ->
                            let c = if | i == start -> btnStart
                                       | i == end -> btnEnd
                                       | otherwise -> btn
                            in (z, c))
                        zones
                        [1..])

    elClass "div" "field is-grouped" $ do
        x <- elClass "p" "control" $ do
                elClass "div" "buttons has-addons" $ do
                    rec (zoom, _) <-
                            elClass' "a" "button" $ do
                                elClass "span" "icon is-small" $
                                    elDynClass "i" zpClass $ return ()
                                el "span" $ dynText zpText

                        zoomOrPan <-
                            (fmap . fmap)
                            (\case True -> Pan; False -> Zoom)
                            (toggle True $ domEvent Click zoom)

                        let zpText = ffor zoomOrPan $ T.pack . (++ " to ...") . show
                        let zpClass = ffor zoomOrPan zoomOrPanIcon

                    (extents, _) <- elAttr' "a" ("class" =: "button") $ text "Extents"
                    let allZones = zones <$ domEvent Click extents

                    eachZone <- sequence $ zoomButton <$> zoneClasses speedSection
                    zs <- holdDyn zones . leftmost $ allZones : eachZone
                    return $ (zoomOrPan, zs)

        dd <- elClass "p" "control" $ do
            elClass "span" "select" $
                dropdown 0 ps' def

        let isSelected = ffor (value dd) (/= 0)

        rec (download, _)
                    <- elClass "p" "control" $ do
                        elDynAttr' "a" downloadAttrs  $ do
                            elClass "span" "icon is-small" $
                                elDynClass "i" downloadClass $ return ()
                            el "span" $ text "Fetch Track"

            let eDownload = domEvent Click download

            downloadClass <- holdDyn "fa fa-download" $ leftmost
                                [ "fa fa-spinner" <$ eDownload
                                , "fa fa-download" <$ eDownloaded
                                ]
            downloadAttrs <- holdDyn ("class" =: "button is-link") $ leftmost
                                [ "class" =: "button is-link" <$ eDownload
                                , "class" =: "button is-link" <$ eDownloaded
                                , ffor (updated isSelected) (\case
                False -> "class" =: "button is-link" <> "disabled" =: ""
                True -> "class" =: "button is-link")
                                ]

        let p = ffor2 (value dd) ps pilotAtIdx
        let y = fforMaybe (tagPromptlyDyn p $ eDownload) id

        return (fst x, snd x, y)

showLatLng :: (Double, Double) -> String
showLatLng (lat, lng) =
    printf fmt (abs lat) (abs lng)
    where
        fmt = case (lat < 0, lng < 0) of
                  (True, True) -> "%f °S, %f °W"
                  (False, True) -> "%f °N, %f °W"
                  (True, False) -> "%f °S, %f °E"
                  (False, False) -> "%f °N, %f °E"

newtype TurnpointName = TurnpointName String
newtype Color = Color String

marker :: Color -> (Double, Double) -> IO L.Marker
marker _ latLng = do
    mark <- L.marker latLng
    L.markerPopup mark $ showLatLng latLng
    return mark

fixMarker :: PilotName -> TimeZone -> Fix -> IO L.Marker
fixMarker
    (PilotName pn)
    tz
    Fix
        { fix
        , time
        , lat = RawLat lat
        , lng = RawLng lng
        } = do
    let latLng = (fromRational lat, fromRational lng)
    fixMark <- L.marker latLng

    let msg =
            pn
            ++ "<br>"
            ++ "#"
            ++ show fix
            ++ " at "
            ++ showTime tz time
            ++ "<br>"
            ++ showLatLng latLng

    L.markerPopup fixMark msg
    return fixMark

tagMarkers :: PilotName -> TimeZone -> ZoneTag -> IO [L.Marker]
tagMarkers
    p@(PilotName pn)
    tz
    ZoneTag
        { inter =
            InterpolatedFix
                { fixFrac
                , time
                , lat = RawLat lat
                , lng = RawLng lng
                }
        , cross = ZoneCross{crossingPair = xy}
        } = do
    let latLng = (fromRational lat, fromRational lng)
    tagMark <- L.marker latLng

    let msg =
            pn
            ++ "<br>"
            ++ "#"
            ++ printf "%.2f" fixFrac
            ++ " at "
            ++ showTime tz time
            ++ "<br>"
            ++ showLatLng latLng

    L.markerPopup tagMark msg

    case xy of
        [x, y] -> do
            xMark <- fixMarker p tz x
            yMark <- fixMarker p tz y
            return [xMark, tagMark, yMark]

        _ -> return [tagMark]

tpMarker :: TurnpointName -> (Double, Double) -> IO L.Marker
tpMarker (TurnpointName tpName) latLng = do
    xMark <- L.marker latLng
    L.markerPopup xMark tpName
    return xMark

tpCircle
    :: Color
    -> (Double, Double)
    -> (Radius, Maybe Radius)
    -> IO (L.Circle, Maybe L.Circle)
tpCircle (Color color) latLng (Radius rx, g) = do
    xCyl <- L.circle latLng rx color False True
    yCyl <- sequence $ (\(Radius ry) -> L.circle latLng ry color True False) <$> g
    return (xCyl, yCyl)

tpLine
    :: Color
    -> (Double, Double)
    -> (Radius, Maybe Radius)
    -> AzimuthFwd
    -> IO (L.Semicircle, Maybe L.Semicircle)
tpLine (Color color) latLng (Radius rx, g) az = do
    xCyl <- L.semicircle latLng rx az color False True
    yCyl <- sequence $ (\(Radius ry) -> L.semicircle latLng ry az color True False) <$> g
    return (xCyl, yCyl)

zoneToLL :: RawZone -> (Double, Double)
zoneToLL RawZone{lat = RawLat lat', lng = RawLng lng'} =
    (fromRational lat', fromRational lng')

zoneToLLR :: RawZone -> (Double, Double, Double)
zoneToLLR RawZone{lat = RawLat lat', lng = RawLng lng', radius = Radius r} =
    (fromRational lat', fromRational lng', r)

rawToLL :: RawLatLng -> (Double, Double)
rawToLL RawLatLng{lat = RawLat lat', lng = RawLng lng'} =
    (fromRational lat', fromRational lng')

viewMap
    :: MonadWidget t m
    => Dynamic t UtcOffset
    -> IxTask
    -> Dynamic t Task
    -> Dynamic t (OptimalRoute (Maybe TrackLine))
    -> Dynamic t (OptimalRoute (Maybe TrackLine))
    -> Dynamic t (Maybe TrackLine)
    -> Dynamic t (Maybe TrackLine)
    -> Event t
        (
            (Pilot
            ,
                ( (Pilot, Maybe TrackFlyingSection)
                , (Pilot, Maybe TrackScoredSection)
                )
            )
        ,
            ( (Pilot, [[Double]])
            , (Pilot, [Maybe ZoneTag])
            )
        )
    -> m (Event t Pilot)
viewMap utcOffset ix task sRoute eRoute pRoute nRoute pilotFlyingTrack = do
    task' <- sample . current $ task
    sRoute' <- sample . current $ sRoute
    eRoute' <- sample . current $ eRoute
    pRoute' <- sample . current $ pRoute
    nRoute' <- sample . current $ nRoute

    map
        utcOffset
        ix
        task'
        (optimalTaskRoute sRoute')
        (optimalTaskRouteSubset sRoute')
        (optimalSpeedRoute sRoute')
        (optimalTaskRoute eRoute')
        (optimalTaskRouteSubset eRoute')
        (optimalSpeedRoute eRoute')
        (lineToRoute pRoute')
        (lineToRoute nRoute')
        pilotFlyingTrack

splitZones :: Task -> ([RawZone], [(AzimuthFwd, RawZone)])
splitZones task@Task{zones = Zones{raw = xs}} =
    case (getGoalShape task, reverse xs) of
        (Just Circle, _) -> (xs, [])
        (Just Cylinder, _) -> (xs, [])
        (Just (Vector _), _) -> (xs, [])
        (Just Star, _) -> (xs, [])
        (_, []) -> (xs, [])
        (_, [_]) -> (xs, [])
        (_, y@RawZone{lat = yLat, lng = yLng} : ys@(RawZone{lat, lng} : _)) ->
            case azimuthFwd (RawLatLng yLat yLng) (RawLatLng lat lng) of
                Nothing -> (xs, [])
                Just az -> (reverse ys, [(azimuthFlip az, y)])

map
    :: MonadWidget t m
    => Dynamic t UtcOffset
    -> IxTask
    -> Task
    -> TaskRoute
    -> TaskRouteSubset
    -> SpeedRoute
    -> TaskRoute
    -> TaskRouteSubset
    -> SpeedRoute
    -> TaskRoute
    -> TaskRoute
    -> Event t
        (
            (Pilot
            ,
                ( (Pilot, Maybe TrackFlyingSection)
                , (Pilot, Maybe TrackScoredSection)
                )
            )
        ,
            ( (Pilot, [[Double]])
            , (Pilot, [Maybe ZoneTag])
            )
        )
    -> m (Event t Pilot)

map _ _ Task{zones = Zones{raw = []}} _ _ _ _ _ _ _ _ _ = do
    el "p" $ text "The task has no turnpoints."
    return never

map _ _ _ (TaskRoute []) _ _ _ _ _ _ _ _ = do
    return never

map _ _ _ _ (TaskRouteSubset []) _ _ _ _ _ _ _ = do
    el "p" $ text "The optimal task route speed section has no turnpoints."
    return never

map _ _ _ _ _ (SpeedRoute []) _ _ _ _ _ _ = do
    el "p" $ text "The optimal route through only the speed section has no turnpoints."
    return never

map
    utcOffset
    ix
    task@Task{zones = Zones{raw = xs}, speedSection}
    (TaskRoute taskSphericalRoute)
    (TaskRouteSubset taskSphericalRouteSubset)
    (SpeedRoute speedSphericalRoute)
    (TaskRoute taskEllipsoidRoute)
    (TaskRouteSubset taskEllipsoidRouteSubset)
    (SpeedRoute speedEllipsoidRoute)
    (TaskRoute taskPlanarRoute)
    (TaskRoute taskNormRoute)
    pilotFlyingTrack = do

    let tpNames = fmap (\RawZone{..} -> TurnpointName zoneName) xs
    pb <- delay 1 =<< getPostBuild

    tz <- sample . current $ timeZone <$> utcOffset
    pilots <- holdDyn [] =<< getTaskPilotDf ix pb
    (zoomOrPan, evZoom, activePilot)
        <- taskZoneButtons task pilots $ () <$ pilotFlyingTrack

    (eCanvas, _) <- elAttr' "div" ("style" =: "height: 680px;width: 100%") $ return ()

    rec performEvent_ $ leftmost
            [ ffor pb (\_ -> liftIO $ do
                L.mapInvalidateSize lmap'
                L.fitBounds lmap' bounds'
                return ())

            , updated $ ffor2 zoomOrPan evZoom (\zp zs -> liftIO $ do
                bs <- L.latLngBounds $ zoneToLLR <$> zs

                case zp of
                    Zoom -> L.fitBounds lmap' bs
                    Pan -> L.panToBounds lmap' bs

                return ())

            , ffor pilotFlyingTrack (\((p, ((_, flying), (_, scored))), ((_, pts), (_, tags))) ->
                if p == nullPilot || null pts then return () else
                case (flying, scored) of
                    (Nothing, _) -> return ()
                    (_, Nothing) -> return ()
                    (Just TrackFlyingSection{flyingFixes = Nothing}, _) -> return ()
                    (_, Just TrackScoredSection{scoredFixes = Nothing}) -> return ()
                    (Just TrackFlyingSection{flyingFixes = Just (i, _)}
                        , Just TrackScoredSection{scoredFixes = Just (j0, jN)}) -> liftIO $ do

                        let pn@(PilotName pn') = getPilotName p
                        let n = jN - (j0 - i)
                        let t0 = take n pts
                        let t1 = drop n pts

                        tagMarks <- sequence $ tagMarkers pn tz <$> catMaybes tags

                        l0 <- L.trackLine t0 "black"
                        g0 <- L.layerGroup l0 $ concat tagMarks

                        -- NOTE: Adding the track now so that it displays.
                        L.layerGroupAddToMap g0 lmap'

                        L.addOverlay layers' (PilotName (pn' <> " scored"), g0)
                        L.layersExpand layers'

                        l1 <- L.discardLine t1 "black"
                        g1 <- L.layerGroup l1 []
                        L.addOverlay layers' (PilotName (pn' <> " not scored"), g1)
                        L.layersExpand layers'

                        return ())
            ]

        (lmap', bounds', layers') <- liftIO $ do
            lmap <- L.map (_element_raw eCanvas)
            L.mapSetView lmap (zoneToLL $ head xs) 11

            mapLayer <-
                -- SEE: http://leaflet-extras.github.io/leaflet-providers/preview/
                L.tileLayer
                    "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                    17

            let xsLen = length xs
            let cs = zoneColors xsLen speedSection
            let (xsCircle, xsLine) = splitZones task
            let (csCircle, csLine) =
                    let csLen = length xsCircle in (take csLen cs, drop csLen cs)

            let pts :: [(Double, Double)] = fmap zoneToLL xs
            let ptsCircle :: [(Double, Double)] = fmap zoneToLL xsCircle
            let ptsLine :: [(Double, Double)] = fmap zoneToLL $ snd <$> xsLine

            let ptsTaskNormRoute :: [(Double, Double)] = fmap rawToLL taskNormRoute

            let ptsTaskSphericalRoute :: [(Double, Double)] = fmap rawToLL taskSphericalRoute
            let ptsTaskSphericalRouteSubset :: [(Double, Double)] = fmap rawToLL taskSphericalRouteSubset
            let ptsSpeedSphericalRoute :: [(Double, Double)] = fmap rawToLL speedSphericalRoute

            let ptsTaskEllipsoidRoute :: [(Double, Double)] = fmap rawToLL taskEllipsoidRoute
            let ptsTaskEllipsoidRouteSubset :: [(Double, Double)] = fmap rawToLL taskEllipsoidRouteSubset
            let ptsSpeedEllipsoidRoute :: [(Double, Double)] = fmap rawToLL speedEllipsoidRoute

            let ptsTaskPlanarRoute :: [(Double, Double)] = fmap rawToLL taskPlanarRoute

            tpMarks <-
                sequence $
                    zipWith
                        tpMarker
                        tpNames
                        pts

            tpCircles <-
                sequence $
                    zipWith3
                        tpCircle
                        csCircle
                        ptsCircle
                        ((\x -> (radius x, give x)) <$> xsCircle)

            _ <- sequence $ ((flip L.circleAddToMap) lmap . fst) <$> tpCircles

            let giveCircles = catMaybes $ snd <$> tpCircles
            _ <- sequence $ (flip L.circleAddToMap) lmap <$> giveCircles

            tpLines <-
                sequence $
                    zipWith4
                        tpLine
                        csLine
                        ptsLine
                        ((\x -> (radius x, give x)) . snd <$> xsLine)
                        (fst <$> xsLine)

            _ <- sequence $ ((flip L.semicircleAddToMap) lmap . fst) <$> tpLines

            let giveLines = catMaybes $ snd <$> tpLines
            _ <- sequence $ (flip L.semicircleAddToMap) lmap <$> giveLines

            courseLine <- L.routeLine pts "gray"
            courseGroup <- L.layerGroup courseLine tpMarks

            taskNormRouteLine <- L.routeLine ptsTaskNormRoute "black"
            taskNormRouteMarks <- sequence $ zipWith marker cs ptsTaskNormRoute
            taskNormRouteGroup <- L.layerGroup taskNormRouteLine taskNormRouteMarks

            taskSphericalRouteLine <- L.routeLine ptsTaskSphericalRoute "red"
            taskSphericalRouteMarks <- sequence $ zipWith marker cs ptsTaskSphericalRoute
            taskSphericalRouteGroup <- L.layerGroup taskSphericalRouteLine taskSphericalRouteMarks

            taskSphericalRouteSubsetLine <- L.routeLine ptsTaskSphericalRouteSubset "green"
            taskSphericalRouteSubsetMarks <- sequence $ zipWith marker cs ptsTaskSphericalRouteSubset
            taskSphericalRouteSubsetGroup <- L.layerGroup taskSphericalRouteSubsetLine taskSphericalRouteSubsetMarks

            speedSphericalRouteLine <- L.routeLine ptsSpeedSphericalRoute "magenta"
            speedSphericalRouteMarks <- sequence $ zipWith marker cs ptsSpeedSphericalRoute
            speedSphericalRouteGroup <- L.layerGroup speedSphericalRouteLine speedSphericalRouteMarks

            taskEllipsoidRouteLine <- L.routeLine ptsTaskEllipsoidRoute "crimson"
            taskEllipsoidRouteMarks <- sequence $ zipWith marker cs ptsTaskEllipsoidRoute
            taskEllipsoidRouteGroup <- L.layerGroup taskEllipsoidRouteLine taskEllipsoidRouteMarks

            taskEllipsoidRouteSubsetLine <- L.routeLine ptsTaskEllipsoidRouteSubset "lime"
            taskEllipsoidRouteSubsetMarks <- sequence $ zipWith marker cs ptsTaskEllipsoidRouteSubset
            taskEllipsoidRouteSubsetGroup <- L.layerGroup taskEllipsoidRouteSubsetLine taskEllipsoidRouteSubsetMarks

            speedEllipsoidRouteLine <- L.routeLine ptsSpeedEllipsoidRoute "cyan"
            speedEllipsoidRouteMarks <- sequence $ zipWith marker cs ptsSpeedEllipsoidRoute
            speedEllipsoidRouteGroup <- L.layerGroup speedEllipsoidRouteLine speedEllipsoidRouteMarks

            taskPlanarRouteLine <- L.routeLine ptsTaskPlanarRoute "salmon"
            taskPlanarRouteMarks <- sequence $ zipWith marker cs ptsTaskPlanarRoute
            taskPlanarRouteGroup <- L.layerGroup taskPlanarRouteLine taskPlanarRouteMarks

            -- NOTE: Adding the route now so that it displays by default but
            -- can also be hidden via the layers control. The course line is
            -- not added by default but can be shown via the layers control.
            L.layerGroupAddToMap taskSphericalRouteGroup lmap

            L.tileLayerAddToMap mapLayer lmap

            layers <-
                L.layersControl
                    mapLayer
                    lmap
                    courseGroup
                    taskNormRouteGroup
                    taskSphericalRouteGroup
                    taskSphericalRouteSubsetGroup
                    speedSphericalRouteGroup
                    taskEllipsoidRouteGroup
                    taskEllipsoidRouteSubsetGroup
                    speedEllipsoidRouteGroup
                    taskPlanarRouteGroup

            bounds <- L.latLngBounds $ zoneToLLR <$> xs

            return (lmap, bounds, layers)

    return activePilot

blues :: [Color]
blues = repeat $ Color "blue"

yellows :: [Color]
yellows = repeat $ Color "yellow"

zoneColors :: Int -> SpeedSection -> [Color]
zoneColors _ Nothing = blues
zoneColors len (Just (start, end)) =
    if len < 2 then blues else
    prolog <> [Color "green"] <> xs' <> [Color "red"] <> yellows
    where
        -- NOTE: The speed section uses 1-based indexing.
        start' = fromIntegral start
        end' = fromIntegral end

        prolog = take (start' - 1) $ yellows
        xs' = take ((end' - start' + 1) - 2) blues
