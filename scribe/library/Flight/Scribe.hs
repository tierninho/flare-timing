module Flight.Scribe
    ( readComp, writeComp
    , readRoute, writeRoute
    , readCrossing , writeCrossing
    , readTagging, writeTagging
    , readMasking, writeMasking
    , readLanding, writeLanding
    , readPointing, writePointing
    , module Flight.Align
    , module Flight.Discard
    ) where

import Control.Monad.Except (ExceptT(..), lift)
import qualified Data.ByteString as BS
import Data.Yaml (ParseException, decodeEither')
import qualified Data.Yaml.Pretty as Y

import Flight.Route (TaskRoute(..))
import Flight.Track.Tag (Tagging(..))
import Flight.Track.Cross (Crossing)
import Flight.Track.Mask (Masking)
import Flight.Track.Land (Landing)
import Flight.Track.Point (Pointing)
import Flight.Field (FieldOrdering(..))
import Flight.Comp
    ( CompInputFile(..)
    , TaskLengthFile(..)
    , CrossZoneFile(..)
    , TagZoneFile(..)
    , MaskTrackFile(..)
    , LandOutFile(..)
    , GapPointFile(..)
    , CompSettings(..)
    )
import Flight.Align
import Flight.Discard

readComp :: CompInputFile -> ExceptT ParseException IO (CompSettings k)
readComp (CompInputFile path) = do
    contents <- lift $ BS.readFile path
    ExceptT . return $ decodeEither' contents

writeComp :: CompInputFile -> CompSettings k -> IO ()
writeComp (CompInputFile path) compInput = do
    let cfg = Y.setConfCompare (fieldOrder compInput) Y.defConfig
    let yaml = Y.encodePretty cfg compInput
    BS.writeFile path yaml

readRoute :: TaskLengthFile -> ExceptT ParseException IO TaskRoute
readRoute (TaskLengthFile path) = do
    contents <- lift $ BS.readFile path
    ExceptT . return $ decodeEither' contents

writeRoute :: TaskLengthFile -> TaskRoute -> IO ()
writeRoute (TaskLengthFile lenPath) route = 
    BS.writeFile lenPath yaml
    where
        cfg = Y.setConfCompare (fieldOrder route) Y.defConfig
        yaml = Y.encodePretty cfg route

readCrossing :: CrossZoneFile -> ExceptT ParseException IO Crossing
readCrossing (CrossZoneFile path) = do
    contents <- lift $ BS.readFile path
    ExceptT . return $ decodeEither' contents

writeCrossing :: CrossZoneFile -> Crossing -> IO ()
writeCrossing (CrossZoneFile path) crossZone = do
    let cfg = Y.setConfCompare (fieldOrder crossZone) Y.defConfig
    let yaml = Y.encodePretty cfg crossZone
    BS.writeFile path yaml

readTagging :: TagZoneFile -> ExceptT ParseException IO Tagging
readTagging (TagZoneFile path) = do
    contents <- lift $ BS.readFile path
    ExceptT . return $ decodeEither' contents

writeTagging :: TagZoneFile -> Tagging -> IO ()
writeTagging (TagZoneFile path) tagZone = do
    let cfg = Y.setConfCompare (fieldOrder tagZone) Y.defConfig
    let yaml = Y.encodePretty cfg tagZone
    BS.writeFile path yaml

readMasking :: MaskTrackFile -> ExceptT ParseException IO Masking
readMasking (MaskTrackFile path) = do
    contents <- lift $ BS.readFile path
    ExceptT . return $ decodeEither' contents

writeMasking :: MaskTrackFile -> Masking -> IO ()
writeMasking (MaskTrackFile path) maskTrack = do
    let cfg = Y.setConfCompare (fieldOrder maskTrack) Y.defConfig
    let yaml = Y.encodePretty cfg maskTrack
    BS.writeFile path yaml

readLanding :: LandOutFile -> ExceptT ParseException IO Landing
readLanding (LandOutFile path) = do
    contents <- lift $ BS.readFile path
    ExceptT . return $ decodeEither' contents

writeLanding :: LandOutFile -> Landing -> IO ()
writeLanding (LandOutFile path) landout = do
    let cfg = Y.setConfCompare (fieldOrder landout) Y.defConfig
    let yaml = Y.encodePretty cfg landout
    BS.writeFile path yaml

readPointing :: GapPointFile -> ExceptT ParseException IO Pointing
readPointing (GapPointFile path) = do
    contents <- lift $ BS.readFile path
    ExceptT . return $ decodeEither' contents

writePointing :: GapPointFile -> Pointing -> IO ()
writePointing (GapPointFile path) gapPoint = do
    let cfg = Y.setConfCompare (fieldOrder gapPoint) Y.defConfig
    let yaml = Y.encodePretty cfg gapPoint
    BS.writeFile path yaml
