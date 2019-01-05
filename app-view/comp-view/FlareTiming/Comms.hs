module FlareTiming.Comms
    ( GetConstraint
    , getComps
    , getNominals
    , getTasks
    , getTaskLengths
    , getPilots
    , getPilotsStatus
    , getValidity
    , getAllocation
    , getTaskScore
    , getTaskValidityWorking
    , getTaskLengthSphericalEdge
    , getTaskLengthEllipsoidEdge
    , getTaskLengthProjectedEdgeSpherical
    , getTaskLengthProjectedEdgeEllipsoid
    , getTaskLengthProjectedEdgePlanar
    , getTaskPilotDnf
    , getTaskPilotNyp
    , getTaskPilotDf
    , getTaskPilotTrack
    ) where

import Reflex
import Reflex.Dom
import Data.Aeson (FromJSON)
import qualified Data.Text as T (Text, pack)
import Control.Monad.IO.Class (MonadIO)

import WireTypes.Comp (Comp(..), Nominal(..), Task(..))
import WireTypes.Route
import WireTypes.Pilot (PilotTaskStatus(..), Pilot(..), PilotId(..), getPilotId)
import WireTypes.Point
import WireTypes.Validity
import WireTypes.ValidityWorking
import FlareTiming.Events (IxTask(..))

-- NOTE: Possible alternatives for mapUri ...
-- mapUri s = "http://localhost:3000" <> s
-- mapUri s = "http://1976-never-land.flaretiming.com/json" <> s <> ".json"
-- mapUri s = "http://1989-lift-lines.flaretiming.com/json" <> s <> ".json"
-- mapUri s = "http://2012-forbes.flaretiming.com/json" <> s <> ".json"
-- mapUri s = "http://2018-forbes.flaretiming.com/json" <> s <> ".json"
-- mapUri s = "http://2018-dalmatian.flaretiming.com/json" <> s <> ".json"
-- mapUri s = "/json" <> s <> ".json"
mapUri :: T.Text -> T.Text
mapUri s = "http://localhost:3000" <> s

type GetConstraint t m =
    ( PostBuild t m
    , MonadIO (Performable m)
    , HasJSContext (Performable m)
    , PerformEvent t m
    , TriggerEvent t m
    , MonadHold t m
    )

type GetTasksConstraints t m =
    ( MonadIO (Performable m)
    , HasJSContext (Performable m)
    , PerformEvent t m
    , TriggerEvent t m
    )

req :: T.Text -> Maybe T.Text -> XhrRequest ()
req uri md = XhrRequest "GET" (maybe uri id md) def

getTasks
    :: GetTasksConstraints t m
    => Event t a
    -> m (Event t [Task])
getTasks ev = do
    let u = mapUri "/comp-input/tasks"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ ev
    return $ fmapMaybe decodeXhrResponse rsp

getTaskLengths
    :: GetTasksConstraints t m
    => Event t a
    -> m (Event t [TaskDistance])
getTaskLengths ev = do
    let u = mapUri "/task-length"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ ev
    return $ fmapMaybe decodeXhrResponse rsp

getComps
    :: GetConstraint t m
    => ()
    -> m (Dynamic t [Comp])
getComps () = do
    pb :: Event t () <- getPostBuild
    let u = mapUri "/comp-input/comps"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t Comp = fmapMaybe decodeXhrResponse rsp
    xs :: Dynamic t [Comp] <- holdDyn [] (pure <$> es)
    return xs

getNominals
    :: GetConstraint t m
    => ()
    -> m (Dynamic t [Nominal])
getNominals () = do
    pb :: Event t () <- getPostBuild
    let u = mapUri "/comp-input/nominals"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t Nominal = fmapMaybe decodeXhrResponse rsp
    xs :: Dynamic t [Nominal] <- holdDyn [] (pure <$> es)
    return xs

getPilots
    :: GetConstraint t m
    => ()
    -> m (Dynamic t [Pilot])
getPilots () = do
    pb :: Event t () <- getPostBuild
    let u = mapUri "/comp-input/pilots"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t [Pilot] = fmapMaybe decodeXhrResponse rsp
    holdDyn [] es

getPilotsStatus
    :: GetConstraint t m
    => ()
    -> m (Dynamic t [(Pilot, [PilotTaskStatus])])
getPilotsStatus () = do
    pb :: Event t () <- getPostBuild
    let u = mapUri "/gap-point/pilots-status"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t [(Pilot, [PilotTaskStatus])] = fmapMaybe decodeXhrResponse rsp
    holdDyn [] es

getValidity
    :: GetConstraint t m
    => ()
    -> m (Dynamic t [Maybe Validity])
getValidity () = do
    pb :: Event t () <- getPostBuild
    let u = mapUri "/gap-point/validity"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t [Maybe Validity] = fmapMaybe decodeXhrResponse rsp
    holdDyn [] es

getAllocation
    :: GetConstraint t m
    => ()
    -> m (Dynamic t [Maybe Allocation])
getAllocation () = do
    pb :: Event t () <- getPostBuild
    let u = mapUri "/gap-point/allocation"
    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t [Maybe Allocation] = fmapMaybe decodeXhrResponse rsp
    holdDyn [] es

getTaskScore
    :: GetConstraint t m
    => IxTask
    -> m (Dynamic t [(Pilot, Breakdown)])

getTaskScore (IxTask ii) = do
    pb :: Event t () <- getPostBuild

    let u :: T.Text
        u =
            mapUri
            $ "/gap-point/"
            <> (T.pack . show $ ii)
            <> "/score"

    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t [(Pilot, Breakdown)] = fmapMaybe decodeXhrResponse rsp
    holdDyn [] es

getTaskScore IxTaskNone = return $ constDyn []

getTaskValidityWorking
    :: GetConstraint t m
    => IxTask
    -> m (Dynamic t (Maybe ValidityWorking))
getTaskValidityWorking (IxTask ii) = do
    pb :: Event t () <- getPostBuild

    let u :: T.Text
        u =
            mapUri
            $ "/gap-point/"
            <> (T.pack . show $ ii)
            <> "/validity-working"

    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t (Maybe ValidityWorking) = fmapMaybe decodeXhrResponse rsp
    holdDyn Nothing es

getTaskValidityWorking IxTaskNone = return $ constDyn Nothing

emptyRoute :: OptimalRoute (Maybe a)
emptyRoute =
    OptimalRoute
        { taskRoute = Nothing
        , taskRouteSpeedSubset = Nothing
        , speedRoute = Nothing
        }

getTaskLength_
    :: GetConstraint t m
    => T.Text
    -> IxTask
    -> m (Dynamic t (OptimalRoute (Maybe TrackLine)))
getTaskLength_ path (IxTask ii) = do
    pb :: Event t () <- getPostBuild

    let u :: T.Text
        u =
            mapUri
            $ "/task-length/"
            <> (T.pack . show $ ii)
            <> "/"
            <> path

    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t (OptimalRoute (Maybe TrackLine)) = fmapMaybe decodeXhrResponse rsp
    holdDyn emptyRoute es

getTaskLength_ _ IxTaskNone = return $ constDyn emptyRoute

getTaskLengthSphericalEdge, getTaskLengthEllipsoidEdge
    :: GetConstraint t m
    => IxTask
    -> m (Dynamic t (OptimalRoute (Maybe TrackLine)))
getTaskLengthSphericalEdge = getTaskLength_ "spherical-edge"
getTaskLengthEllipsoidEdge = getTaskLength_ "ellipsoid-edge"

getTaskLengthProjected_
    :: GetConstraint t m
    => T.Text
    -> IxTask
    -> m (Dynamic t (Maybe TrackLine))
getTaskLengthProjected_ path (IxTask ii) = do
    pb :: Event t () <- getPostBuild

    let u :: T.Text
        u =
            mapUri
            $ "/task-length/"
            <> (T.pack . show $ ii)
            <> "/"
            <> path

    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t TrackLine = fmapMaybe decodeXhrResponse rsp
    holdDyn Nothing $ Just <$> es

getTaskLengthProjected_ _ IxTaskNone = return $ constDyn Nothing

getTaskLengthProjectedEdgeSpherical, getTaskLengthProjectedEdgeEllipsoid
    :: GetConstraint t m
    => IxTask
    -> m (Dynamic t (Maybe TrackLine))
getTaskLengthProjectedEdgeSpherical = getTaskLengthProjected_ "projected-edge-spherical"
getTaskLengthProjectedEdgeEllipsoid = getTaskLengthProjected_ "projected-edge-ellipsoid"

getTaskLengthProjectedEdgePlanar
    :: GetConstraint t m
    => IxTask
    -> m (Dynamic t (Maybe PlanarTrackLine))
getTaskLengthProjectedEdgePlanar (IxTask ii) = do
    pb :: Event t () <- getPostBuild

    let u :: T.Text
        u =
            mapUri
            $ "/task-length/"
            <> (T.pack . show $ ii)
            <> "/projected-edge-planar"

    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t PlanarTrackLine = fmapMaybe decodeXhrResponse rsp
    holdDyn Nothing $ Just <$> es

getTaskLengthProjectedEdgePlanar IxTaskNone = return $ constDyn Nothing

getTaskPilot_
    :: GetConstraint t m
    => T.Text
    -> T.Text
    -> IxTask
    -> m (Dynamic t [Pilot])
getTaskPilot_ stage path (IxTask ii) = do
    pb :: Event t () <- getPostBuild

    let u :: T.Text
        u =
            mapUri
            $ "/"
            <> stage
            <> "/"
            <> (T.pack . show $ ii)
            <> "/"
            <> path


    rsp <- performRequestAsync . fmap (req u) $ Nothing <$ pb

    let es :: Event t [Pilot] = fmapMaybe decodeXhrResponse rsp
    holdDyn [] es

getTaskPilot_ _ _ IxTaskNone = return $ constDyn []

getTaskPilotDnf, getTaskPilotNyp, getTaskPilotDf
    :: GetConstraint t m
    => IxTask
    -> m (Dynamic t [Pilot])
getTaskPilotDnf = getTaskPilot_ "cross-zone" "pilot-dnf"
getTaskPilotNyp = getTaskPilot_ "cross-zone" "pilot-nyp"
getTaskPilotDf = getTaskPilot_ "gap-point" "pilot-df"

getTaskPilotTrack
    ::
        ( MonadIO (Performable m)
        , HasJSContext (Performable m)
        , PerformEvent t m
        , TriggerEvent t m
        , FromJSON a
        )
   => IxTask
   -> Event t Pilot
   -> m (Event t a)
getTaskPilotTrack (IxTask ii) ep = do

    let u :: PilotId -> T.Text
        u (PilotId pid) =
            mapUri
            $ "/pilot-track/"
            <> (T.pack . show $ ii)
            <> "/"
            <> (T.pack pid)

    let req' md = XhrRequest "GET" (u md) def
    rsp <- performRequestAsync . fmap req' $ getPilotId <$> ep

    return $ fmapMaybe decodeXhrResponse rsp

getTaskPilotTrack IxTaskNone _ = return never
