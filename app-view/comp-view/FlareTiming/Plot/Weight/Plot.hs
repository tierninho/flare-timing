{-# LANGUAGE JavaScriptFFI #-}
{-# LANGUAGE ForeignFunctionInterface #-}

module FlareTiming.Plot.Weight.Plot (hgWeightPlot, pgWeightPlot) where

import Prelude hiding (map, log)
import GHCJS.Types (JSVal)
import GHCJS.DOM.Element (IsElement)
import GHCJS.DOM.Types (Element(..), toElement, toJSVal)
import Data.Maybe (fromMaybe)
import FlareTiming.Plot.Foreign (Plot(..))

import WireTypes.Comp (Discipline(..), Tweak(..), LwScaling(..), AwScaling(..))
import WireTypes.Point
    ( GoalRatio(..)
    , DistanceWeight(..)
    , ArrivalWeight(..)
    , LeadingWeight(..)
    , TimeWeight(..)
    , Weights(..)
    )

-- SEE: http://colorbrewer2.org/#type=qualitative&scheme=Set1&n=5
-- red #e41a1c
-- blue #377eb8
-- green #4daf4a
-- purple #984ea3
-- orange #ff7f00
foreign import javascript unsafe
    "functionPlot(\
    \{ target: '#hg-plot-weight'\
    \, title: 'Split of Available Points'\
    \, width: 640\
    \, height: 640\
    \, disableZoom: true\
    \, xAxis: {label: 'Fraction of Pilots in Goal', domain: [0, 1]}\
    \, yAxis: {domain: [0, 1]}\
    \, data: [{\
    \    fn: '0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3'\
    \  , nSamples: 101\
    \  , color: '#377eb8'\
    \  , graphType: 'polyline'\
    \  },{\
    \    points: [[$4, $5]]\
    \  , fnType: 'points'\
    \  , color: '#377eb8'\
    \  , attr: { r: 3 }\
    \  , graphType: 'scatter' \
    \  },{\
    \    fn: '(1 - (0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3))/8 * 1.4 * ' + $2\
    \  , nSamples: 101\
    \  , color: '#e41a1c'\
    \  , graphType: 'polyline'\
    \  },{\
    \    points: [[$4, $6]]\
    \  , fnType: 'points'\
    \  , color: '#e41a1c'\
    \  , attr: { r: 3 }\
    \  , graphType: 'scatter' \
    \  },{\
    \    fn: '(1 - (0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3))/8 * ' + $3\
    \  , nSamples: 101\
    \  , color: '#984ea3'\
    \  , graphType: 'polyline'\
    \  },{\
    \    points: [[$4, $7]]\
    \  , fnType: 'points'\
    \  , color: '#984ea3'\
    \  , attr: { r: 3 }\
    \  , graphType: 'scatter' \
    \  },{\
    \    fn:   '1 - ((0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3) + '\
    \        + '(1 - (0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3))/8 * 1.4 * ' + $2 + ' + '\
    \        + '(1 - (0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3))/8 * ' + $3 + ')'\
    \  , nSamples: 101\
    \  , color: '#4daf4a'\
    \  , graphType: 'polyline'\
    \  },{\
    \    points: [[$4, $8]]\
    \  , fnType: 'points'\
    \  , color: '#4daf4a'\
    \  , attr: { r: 3 }\
    \  , graphType: 'scatter' \
    \  }]\
    \, annotations: [{\
    \    x: $4\
    \  , text: 'pilots in goal'\
    \  }]\
    \})"
    hgPlot_ :: JSVal -> JSVal -> JSVal -> JSVal -> JSVal -> JSVal -> JSVal -> JSVal -> IO JSVal

hgWeightPlot
    :: IsElement e
    => e -> Maybe Tweak -> GoalRatio -> Weights -> IO Plot
hgWeightPlot
    e
    tw
    (GoalRatio gr)
    Weights
        { distance = DistanceWeight d
        , arrival = ArrivalWeight a
        , leading = LeadingWeight l
        , time = TimeWeight t
        } = do

    let Tweak
            { leadingWeightScaling = Just (LwScaling lw)
            , arrivalWeightScaling = Just (AwScaling aw)
            } = scaling HangGliding tw

    lw' <- toJSVal lw
    aw' <- toJSVal aw
    gr' <- toJSVal gr
    d' <- toJSVal d
    a' <- toJSVal a
    l' <- toJSVal l
    t' <- toJSVal t

    Plot <$> hgPlot_ (unElement . toElement $ e) lw' aw' gr' d' l' a' t'

foreign import javascript unsafe
    "functionPlot(\
    \{ target: '#pg-plot-weight'\
    \, title: 'Split of Available Points'\
    \, width: 640\
    \, height: 640\
    \, disableZoom: true\
    \, xAxis: {label: 'Fraction of Pilots in Goal', domain: [0, 1]}\
    \, yAxis: {domain: [0, 1]}\
    \, data: [{\
    \    fn: '0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3'\
    \  , nSamples: 101\
    \  , color: 'blue'\
    \  , graphType: 'polyline'\
    \  },{\
    \    points: [[$3, $4]]\
    \  , fnType: 'points'\
    \  , color: 'blue'\
    \  , attr: { r: 3 }\
    \  , graphType: 'scatter' \
    \  },{\
    \    fn: '(1 - (0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3))/8 * 1.4 * ' + $2\
    \  , nSamples: 101\
    \  , color: 'red'\
    \  , graphType: 'polyline'\
    \  },{\
    \    points: [[$3, $5]]\
    \  , fnType: 'points'\
    \  , color: 'red'\
    \  , attr: { r: 3 }\
    \  , graphType: 'scatter' \
    \  },{\
    \    fn: '1 - ((0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3) + (1 - (0.9 - 1.665*x + 1.713*x^2 - 0.587*x^3))/8 * 1.4 * ' + $2 + ')'\
    \  , nSamples: 101\
    \  , color: 'green'\
    \  , graphType: 'polyline'\
    \  },{\
    \    points: [[$3, $6]]\
    \  , fnType: 'points'\
    \  , color: 'green'\
    \  , attr: { r: 3 }\
    \  , graphType: 'scatter' \
    \  }]\
    \, annotations: [{\
    \    x: $3\
    \  , text: 'pilots in goal'\
    \  }]\
    \})"
    pgPlot_ :: JSVal -> JSVal -> JSVal -> JSVal -> JSVal -> JSVal -> IO JSVal

pgWeightPlot
    :: IsElement e
    => e -> Maybe Tweak -> GoalRatio -> Weights -> IO Plot
pgWeightPlot
    e
    tw
    (GoalRatio gr)
    Weights
        { distance = DistanceWeight d
        , leading = LeadingWeight l
        , time = TimeWeight t
        } = do

    let Tweak{leadingWeightScaling = Just (LwScaling lw)} = scaling Paragliding tw

    lw' <- toJSVal lw
    gr' <- toJSVal gr
    d' <- toJSVal d
    l' <- toJSVal l
    t' <- toJSVal t

    Plot <$> pgPlot_ (unElement . toElement $ e) lw' gr' d' l' t'

scaling :: Discipline -> Maybe Tweak -> Tweak
scaling HangGliding Nothing =
    Tweak
        { leadingWeightScaling = Just (LwScaling 1)
        , arrivalWeightScaling = Just (AwScaling 1)
        }
scaling Paragliding Nothing =
    Tweak
        { leadingWeightScaling = Just (LwScaling 2)
        , arrivalWeightScaling = Just (AwScaling 0)
        }
scaling
    HangGliding
    (Just Tweak{leadingWeightScaling = lw, arrivalWeightScaling = aw}) =
    Tweak
        { leadingWeightScaling = Just lw'
        , arrivalWeightScaling = Just aw'
        }
    where
        lw' = fromMaybe (LwScaling 1) lw
        aw' = fromMaybe (AwScaling 1) aw
scaling
    Paragliding
    (Just Tweak{leadingWeightScaling = lw}) =
    Tweak
        { leadingWeightScaling = Just lw'
        , arrivalWeightScaling = Just (AwScaling 0)
        }
    where
        lw' = fromMaybe (LwScaling 2) lw
