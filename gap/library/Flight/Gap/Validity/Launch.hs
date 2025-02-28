module Flight.Gap.Validity.Launch (LaunchValidity(..)) where

import Data.Typeable (Typeable, typeOf)
import "newtype" Control.Newtype (Newtype(..))
import Data.Via.Scientific
    (DecimalPlaces(..), deriveDecimalPlaces, deriveJsonViaSci, deriveShowViaSci)

newtype LaunchValidity = LaunchValidity Rational
    deriving (Eq, Ord, Typeable)

instance Newtype LaunchValidity Rational where
    pack = LaunchValidity
    unpack (LaunchValidity a) = a

deriveDecimalPlaces (DecimalPlaces 8) ''LaunchValidity
deriveJsonViaSci ''LaunchValidity
deriveShowViaSci ''LaunchValidity
