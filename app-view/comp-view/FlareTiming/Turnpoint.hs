{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE KindSignatures #-}

module FlareTiming.Turnpoint
    ( turnpoint
    , turnpointRadius
    , getName
    , getNameRadius
    ) where

import Reflex.Dom (MonadWidget, Dynamic, dynText)
import qualified Data.Text as T (pack)

import Data.Flight.Types (RawZone(..), showRadius)

getNameRadius :: RawZone -> String
getNameRadius (RawZone name _ _ radius) = name ++ " " ++ showRadius radius

getName :: RawZone -> String
getName (RawZone name _ _ _) = name

turnpointRadius :: forall t (m :: * -> *). MonadWidget t m => Dynamic t RawZone -> m ()
turnpointRadius x = do
    dynText $ fmap (T.pack . getNameRadius) x

turnpoint :: forall t (m :: * -> *). MonadWidget t m => Dynamic t RawZone -> m ()
turnpoint x = do
    dynText $ fmap (T.pack . getName) x
