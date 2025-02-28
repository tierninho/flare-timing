    let defs = ./../defaults.dhall

in    defs
    ⫽ ./../default-extensions.dhall
    ⫽ { name =
          "flight-gap"
      , synopsis =
          "GAP Scoring."
      , description =
          "GAP scoring for hang gliding and paragliding competitons."
      , category =
          "Flight"
      , github =
          "blockscope/flare-timing/gap"
      , ghc-options =
          [ "-Wall"
          , "-fplugin Data.UnitsOfMeasure.Plugin"
          , "-fno-warn-partial-type-signatures"
          ]
      , dependencies =
            defs.dependencies
          # [ "aeson"
            , "cassava"
            , "containers"
            , "newtype"
            , "scientific"
            , "template-haskell"
            , "text"
            , "uom-plugin"
            , "detour-via-sci"
            , "detour-via-uom"
            , "siggy-chardust"
            , "flight-units"
            ]
      , library =
          { source-dirs =
              "library"
          , exposed-modules =
              [ "Flight.Score", "Flight.Gap.Fraction" ]
          }
      , tests =
            ./../default-tests.dhall
          ⫽ { score =
                { dependencies =
                    [ "base"
                    , "containers"
                    , "vector"
                    , "statistics"
                    , "aeson"
                    , "newtype"
                    , "scientific"
                    , "uom-plugin"
                    , "detour-via-sci"
                    , "detour-via-uom"
                    , "siggy-chardust"
                    , "flight-units"
                    , "tasty"
                    , "tasty-hunit"
                    , "tasty-quickcheck"
                    , "tasty-smallcheck"
                    , "smallcheck"
                    ]
                , ghc-options =
                    [ "-rtsopts"
                    , "-threaded"
                    , "-with-rtsopts=-N"
                    , "-fplugin Data.UnitsOfMeasure.Plugin"
                    ]
                , main =
                    "Score.hs"
                , source-dirs =
                    [ "library", "test-suite-score" ]
                }
            , doctest =
                { dependencies =
                    defs.dependencies # [ "doctest" ]
                , ghc-options =
                    [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
                , main =
                    "DocTest.hs"
                , source-dirs =
                    [ "library", "test-suite-doctest" ]
                }
            }
      }
