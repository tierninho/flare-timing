module Main (main) where

import Test.DocTest (doctest)

arguments :: [String]
arguments =
    [ "-isrc"
    , "library/Flight/Igc/Record.hs"
    , "library/Flight/Igc/Parse.hs"
    , "library/Flight/Igc/Fix.hs"
    , "-XFlexibleContexts"
    , "-XFlexibleInstances"
    , "-XGADTs"
    , "-XParallelListComp"
    , "-XScopedTypeVariables"
    , "-XDeriveGeneric"
    , "-XNamedFieldPuns"
    , "-XMultiWayIf"
    ]

main :: IO ()
main = doctest arguments
