module FlareTiming.Turnpoint
    ( turnpoint
    , turnpointRadius
    , getName
    , getLat
    , getLng
    , getRadius
    , getGive
    , getAlt
    ) where

import Reflex.Dom (MonadWidget, Dynamic, dynText)
import qualified Data.Text as T (Text, pack)

import WireTypes.Zone (RawZone(..))
import WireTypes.ZoneKind (showRadius, showLat, showLng, showAlt)

getNameRadius :: RawZone -> T.Text
getNameRadius RawZone{zoneName,radius} =
    T.pack $ zoneName ++ " " ++ showRadius radius

getName :: RawZone -> T.Text
getName RawZone{zoneName} = T.pack zoneName

getLat :: RawZone -> T.Text
getLat RawZone{lat} = T.pack . showLat $ lat

getLng :: RawZone -> T.Text
getLng RawZone{lng} = T.pack . showLng $ lng

getRadius :: RawZone -> T.Text
getRadius RawZone{radius} = T.pack . showRadius $ radius

getGive :: RawZone -> T.Text
getGive RawZone{give} = maybe "" (T.pack . showRadius) give

getAlt :: RawZone -> T.Text
getAlt RawZone{alt} = maybe "" (T.pack . showAlt) alt

turnpointRadius
    :: MonadWidget t m
    => Dynamic t RawZone
    -> m ()
turnpointRadius x = do
    dynText $ fmap getNameRadius x

turnpoint
    :: MonadWidget t m
    => Dynamic t RawZone
    -> m ()
turnpoint x = do
    dynText $ fmap getName x
