  ./defaults.dhall 
⫽ { name =
      "detour-via-uom"
  , version =
      "1.0.0"
  , synopsis =
      "JSON and CSV encoding for quantities."
  , description =
      "Lossy JSON and CSV encoding and decoding for newtype quantities via scientific with fixed decimal places and with units."
  , category =
      "Data, Math, Numeric, JSON, CSV, Physics"
  , github =
      "blockscope/flare-timing/detour-via-uom"
  , homepage =
      "https://github.com/blockscope/flare-timing/tree/master/detour-via-uom#readme"
  , ghc-options =
      [ "-Wall", "-fplugin Data.UnitsOfMeasure.Plugin" ]
  , library =
      { dependencies =
          [ "base >=4.5 && <5"
          , "newtype"
          , "scientific"
          , "aeson"
          , "cassava"
          , "uom-plugin"
          , "detour-via-sci"
          ]
      , source-dirs =
          "library"
      , exposed-modules =
          [ "Data.Via.UnitsOfMeasure" ]
      }
  , tests =
      { doctest =
          { dependencies =
              [ "base"
              , "newtype"
              , "scientific"
              , "aeson"
              , "cassava"
              , "uom-plugin"
              , "detour-via-sci"
              , "doctest"
              ]
          , ghc-options =
              [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
          , main =
              "DocTest.hs"
          , source-dirs =
              [ "library", "test-suite-doctest" ]
          }
      , hlint =
          { dependencies =
              [ "base"
              , "hlint"
              , "newtype"
              , "scientific"
              , "aeson"
              , "cassava"
              , "uom-plugin"
              , "detour-via-sci"
              ]
          , ghc-options =
              [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
          , main =
              "HLint.hs"
          , source-dirs =
              [ "library", "test-suite-hlint" ]
          }
      }
  }
