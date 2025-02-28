module Flight.Gap.Validity.Area (NominalDistanceArea(..)) where

import Data.Typeable (Typeable, typeOf)
import "newtype" Control.Newtype (Newtype(..))
import Data.Via.Scientific
    (DecimalPlaces(..), deriveDecimalPlaces, deriveJsonViaSci, deriveShowViaSci)

newtype NominalDistanceArea = NominalDistanceArea Rational
    deriving (Eq, Ord, Typeable)

instance Newtype NominalDistanceArea Rational where
    pack = NominalDistanceArea
    unpack (NominalDistanceArea a) = a

deriveDecimalPlaces (DecimalPlaces 8) ''NominalDistanceArea
deriveJsonViaSci ''NominalDistanceArea
deriveShowViaSci ''NominalDistanceArea
