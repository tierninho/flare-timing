{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

module Flight.Zone.MkZones
    ( Discipline(..)
    , Decelerator(..)
    , CessIncline(..)
    , EssVsGoal(..)
    , GoalLine(..)
    , Zones(..)
    , mkZones
    , unkindZones
    ) where

import GHC.Generics (Generic)
import Data.Aeson
    ( ToJSON(..), FromJSON(..), Options(..)
    , defaultOptions, genericToJSON, genericParseJSON
    )
import Data.UnitsOfMeasure (u, convert, fromRational')
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.Units ()
import Flight.LatLng (LatLng(..), Lat(..), Lng(..), QAlt)
import Flight.Zone.Raw (RawZone)
import qualified Flight.Zone.Zone as Z (Zone(..), toCylinder)
import Flight.Zone (QAltTime, QIncline, Incline(..))
import Flight.Zone.Internal.ZoneKind
    ( ZoneKind(..), Race, OpenDistance
    , Turnpoint, EndOfSpeedSection, Goal
    , EssAllowedZone, GoalAllowedZone
    )
import Flight.Zone.TaskZones
    (TaskZones(..), ToZoneKind, raceZoneKinds, openZoneKinds)
import Flight.Zone.SpeedSection (SpeedSection)

data Discipline
    = HangGliding
    | Paragliding
    deriving (Eq, Ord, Generic)

disciplineOptions :: Options
disciplineOptions =
    defaultOptions
        { constructorTagModifier = \case
            "HangGliding" -> "hg"
            "Paragliding" -> "pg"
            x -> x
        }

instance Show Discipline where
    show HangGliding = "hg"
    show Paragliding = "pg"

instance Read Discipline where
    readsPrec _ ('h' : 'g' : s) = [(HangGliding, s)]
    readsPrec _ ('p' : 'g' : s) = [(Paragliding, s)]
    readsPrec _ _ = []

instance ToJSON Discipline where
  toJSON = genericToJSON disciplineOptions

instance FromJSON Discipline where
  parseJSON = genericParseJSON disciplineOptions

-- | How many units of distance for each unit of altitude, expressed like
-- a glide ratio, the n of an n : 1 glide.
newtype CessIncline =
    CessIncline Double
    deriving (Eq, Ord, Show)
    deriving newtype Num

data Decelerator
    = CESS CessIncline
    | AATB (QAltTime Double [u| s / m |])
    | NoDecelerator String
    deriving (Eq, Ord, Show)

data EndShape
    = EndLine
    | EndSemiCircle
    | EndCircle
    | EndCylinder
    | EndCutCylinder
    | EndCutSemiCylinder
    | EndCutCone
    | EndCutSemiCone

data EssVsGoal = EssBeforeGoal | EssAtGoal
data GoalLine = GoalLine | GoalNotLine
data DeceleratorShape = DecCyl | DecCone

goalKindShape
    :: Discipline
    -> GoalLine
    -> EssVsGoal
    -> Maybe DeceleratorShape
    -> EndShape
goalKindShape Paragliding GoalLine EssAtGoal (Just DecCone) = EndCutSemiCone
goalKindShape Paragliding _ EssAtGoal (Just DecCone) = EndCutCone
goalKindShape Paragliding GoalLine EssAtGoal (Just DecCyl) = EndCutSemiCylinder
goalKindShape Paragliding _ EssAtGoal (Just DecCyl) = EndCutCylinder
goalKindShape Paragliding GoalLine _ _ = EndSemiCircle
goalKindShape _ GoalLine _ _ = EndLine
goalKindShape _ _ _ _ = EndCircle

essKindShape
    :: Discipline
    -> GoalLine
    -> EssVsGoal
    -> Maybe DeceleratorShape
    -> EndShape
essKindShape Paragliding GoalLine EssAtGoal (Just DecCone) = EndCutSemiCone
essKindShape Paragliding _ _ (Just DecCone) = EndCutCone
essKindShape Paragliding GoalLine EssAtGoal _ = EndCutSemiCylinder
essKindShape Paragliding _ _ _ = EndCutCylinder
essKindShape _ _ _ _ = EndCylinder

tpKindShape :: Discipline -> GoalLine -> EndShape
tpKindShape _ _ = EndCylinder

mkGoalKind
    :: (EssAllowedZone k, GoalAllowedZone k)
    => EndShape
    -> Maybe Decelerator
    -> ToZoneKind k
mkGoalKind EndCutSemiCone (Just (CESS i)) =
    \r x -> \case
        (Just alt) -> CutSemiCone (mkIncline i) r x alt
        Nothing -> SemiCircle r x
mkGoalKind EndCutCone (Just (CESS i)) =
    \r x -> \case
        (Just alt) -> CutCone (mkIncline i) r x alt
        Nothing -> Circle r x
mkGoalKind EndCutSemiCylinder (Just (AATB aatb)) =
    \r x -> \case
        (Just alt) -> CutSemiCylinder aatb r x alt
        Nothing -> SemiCircle r x
mkGoalKind EndCutCylinder (Just (AATB aatb)) =
    \r x -> \case
        (Just alt) -> CutCylinder aatb r x alt
        Nothing -> Circle r x
mkGoalKind EndSemiCircle _ =
    \r x _ -> SemiCircle r x
mkGoalKind EndLine _ =
    \r x _ -> Line r x
mkGoalKind _ _ =
    \r x _ -> Circle r x

mkTpKind :: EndShape -> ToZoneKind Turnpoint
mkTpKind _ r x _ = Cylinder r x

mkEssKind
    :: EndShape
    -> Maybe Decelerator
    -> ToZoneKind EndOfSpeedSection
mkEssKind EndCutSemiCone (Just (CESS i)) =
    \r x -> \case
        (Just alt) -> CutSemiCone (mkIncline i) r x alt
        Nothing -> SemiCircle r x
mkEssKind EndCutCone (Just (CESS i)) =
    \r x -> \case
        (Just alt) -> CutCone (mkIncline i) r x alt
        Nothing -> Cylinder r x
mkEssKind EndCutSemiCylinder (Just (AATB aatb)) =
    \r x -> \case
        (Just alt) -> CutSemiCylinder aatb r x alt
        Nothing -> Cylinder r x
mkEssKind EndCutCylinder (Just (AATB aatb)) =
    \r x -> \case
        (Just alt) -> CutCylinder aatb r x alt
        Nothing -> Cylinder r x
mkEssKind _ _ =
    \r x _ -> Cylinder r x

mkIncline :: CessIncline -> QIncline Double [u| rad |]
mkIncline (CessIncline x) =
    Incline . MkQuantity $ atan2 1 x

data Zones =
    Zones
        { raw :: [RawZone]
        , raceKind :: Maybe (TaskZones Race Double)
        , openKind :: Maybe (TaskZones OpenDistance Double)
        }
    deriving (Eq, Ord, Show, Generic, ToJSON, FromJSON)

raceKindCyl :: EssAllowedZone k => ToZoneKind k
raceKindCyl r x _ = Cylinder r x

openKindCyl :: ToZoneKind OpenDistance
openKindCyl r x _ = Star r x

openKindVec :: LatLng Rational [u| deg |] -> ToZoneKind OpenDistance
openKindVec (LatLng (Lat dLat, Lng dLng)) =
    let rLat :: Quantity _ [u| rad |]
        rLat = fromRational' . convert $ dLat

        rLng :: Quantity _ [u| rad |]
        rLng = fromRational' . convert $ dLng

        y = LatLng (Lat rLat, Lng rLng)

    in \r x _ -> Vector (Left y) r x

mkZones
    :: Discipline
    -> GoalLine
    -> Maybe Decelerator
    -> Maybe (LatLng Rational [u| deg |])
    -> SpeedSection
    -> [Maybe (QAlt Double [u| m |])]
    -> [RawZone]
    -> Zones

mkZones _ _ _ heading Nothing alts zs =
    Zones zs Nothing (g alts zs)
    where
        zsLen = length zs
        psLen = 0
        tsLen = zsLen - psLen - 1

        ok = maybe openKindCyl openKindVec heading

        ps = replicate psLen raceKindCyl
        ts = replicate tsLen raceKindCyl
        g = openZoneKinds ps ts ok

mkZones discipline goalLine decel _ speed@(Just _) alts zs =
    Zones zs (g alts zs) Nothing
    where
        -- The number of zones.
        zsLen = length zs

        -- The number of prolog zones.
        psLen = maybe 0 ((\x -> x - 1) . fst) speed

        -- The number of epilog zones.
        esLen = maybe 0 ((\x -> max 0 $ zsLen - x - 1) . snd) speed

        -- The 1-based index of the end of the speed section.
        ssEnd = maybe zsLen snd speed

        -- The remaining turnpoint zones in the race excluding the zone at the
        -- end of the speed section. That race end zone might be either goal
        -- (when ssEnd == zsLen) or an ESS zone.
        tsLen = zsLen - psLen - esLen - (if ssEnd == zsLen then 1 else 2)

        tpShape = tpKindShape discipline goalLine

        dcShape =
            \case
                CESS 0 -> DecCyl
                CESS _ -> DecCone
                _ -> DecCyl
            <$> decel

        ssEndIsGoal = if ssEnd == zsLen then EssAtGoal else EssBeforeGoal
        gkShape = goalKindShape discipline goalLine ssEndIsGoal dcShape
        ekShape = essKindShape discipline goalLine ssEndIsGoal dcShape 

        gk :: ToZoneKind Goal
        gk = mkGoalKind gkShape decel

        tk = mkTpKind tpShape
        ek = if ssEnd < zsLen then Just $ mkEssKind ekShape decel else Nothing

        ps = replicate psLen tk
        ts = replicate tsLen tk
        es = replicate esLen tk
        g = raceZoneKinds ps ts ek es gk

unkindZones :: Zones -> [Z.Zone Double]
unkindZones Zones{raceKind = Just (TzEssIsGoal ps ts g)} =
    (unkind <$> (ps ++ ts)) ++ [unkind g]
unkindZones Zones{raceKind = Just (TzEssIsNotGoal ps rs e es g)} =
    (unkind <$> (ps ++ rs)) ++ [unkind e] ++ (unkind <$> es) ++ [unkind g]
unkindZones Zones{openKind = Just (TzOpenDistance ps ts o)} =
    (unkind <$> (ps ++ ts)) ++ [unkind o]
unkindZones Zones{raw} = Z.toCylinder <$> raw

unkind :: ZoneKind g Double -> Z.Zone Double
unkind (Point x) = Z.Point x
unkind (Vector _ _ x) = Z.Point x
unkind (Star r x) = Z.Cylinder r x
unkind (Cylinder r x) = Z.Cylinder r x
unkind (CutCone _ r x _) = Z.Cylinder r x
unkind (CutSemiCone _ r x _) = Z.Cylinder r x
unkind (CutCylinder _ r x _) = Z.Cylinder r x
unkind (CutSemiCylinder _ r x _) = Z.Cylinder r x
unkind (Line r x) = Z.Line Nothing r x
unkind (Circle r x) = Z.Cylinder r x
unkind (SemiCircle r x) = Z.Cylinder r x
