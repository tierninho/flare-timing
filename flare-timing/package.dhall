    let defs = ./defaults.dhall 

in  let depsTest =
            defs.dependencies
          # [ "directory"
            , "filepath"
            , "system-filepath"
            , "filemanip"
            , "raw-strings-qq"
            , "cmdargs"
            , "flight-cmd"
            , "flight-comp"
            ]

in  let deps =
            defs.dependencies
          # [ "directory"
            , "filepath"
            , "system-filepath"
            , "filemanip"
            , "raw-strings-qq"
            , "cmdargs"
            , "mtl"
            , "transformers"
            , "yaml"
            , "aeson"
            , "uom-plugin"
            , "bytestring"
            , "clock"
            , "formatting"
            , "flight-cmd"
            , "flight-comp"
            , "flight-latlng"
            , "flight-scribe"
            ]

in    defs
    ⫽ { name =
          "flare-timing"
      , synopsis =
          "A collection of apps and libraries for scoring hang gliding and paragliding competitions."
      , description =
          "Scoring and viewing hang gliding and paragliding competitions."
      , category =
          "Data, Parsing"
      , github =
          "blockscope/flare-timing/flare-timing"
      , executables =
          { extract-input =
              { dependencies =
                  deps # [ "flight-gap", "flight-fsdb" ]
              , ghc-options =
                  [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
              , main =
                  "ExtractInputMain.hs"
              , source-dirs =
                  "prod-apps/extract-input"
              }
          , task-length =
              { dependencies =
                  deps # [ "flight-units", "flight-route" ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "TaskLengthMain.hs"
              , source-dirs =
                  "prod-apps/task-length"
              }
          , cross-zone =
              { dependencies =
                    deps
                  # [ "lens"
                    , "siggy-chardust"
                    , "flight-span"
                    , "flight-units"
                    , "flight-kml"
                    , "flight-track"
                    , "flight-zone"
                    , "flight-earth"
                    , "flight-task"
                    , "flight-mask"
                    ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "CrossZoneMain.hs"
              , source-dirs =
                  "prod-apps/cross-zone"
              }
          , tag-zone =
              { dependencies =
                    deps
                  # [ "time"
                    , "siggy-chardust"
                    , "flight-units"
                    , "flight-kml"
                    , "flight-track"
                    , "flight-task"
                    , "flight-mask"
                    ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "TagZoneMain.hs"
              , source-dirs =
                  "prod-apps/tag-zone"
              }
          , align-time =
              { dependencies =
                    deps
                  # [ "clock"
                    , "lens"
                    , "time"
                    , "uom-plugin"
                    , "siggy-chardust"
                    , "flight-units"
                    , "flight-kml"
                    , "flight-track"
                    , "flight-zone"
                    , "flight-task"
                    , "flight-mask"
                    , "flight-lookup"
                    ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "AlignTimeMain.hs"
              , source-dirs =
                  "prod-apps/align-time"
              }
          , discard-further =
              { dependencies =
                    deps
                  # [ "siggy-chardust"
                    , "flight-units"
                    , "flight-kml"
                    , "flight-track"
                    , "flight-zone"
                    , "flight-route"
                    , "flight-task"
                    , "flight-gap"
                    , "flight-mask"
                    , "flight-lookup"
                    ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "DiscardFurtherMain.hs"
              , source-dirs =
                  "prod-apps/discard-further"
              }
          , mask-track =
              { dependencies =
                    deps
                  # [ "containers"
                    , "lens"
                    , "siggy-chardust"
                    , "flight-span"
                    , "flight-units"
                    , "flight-kml"
                    , "flight-track"
                    , "flight-zone"
                    , "flight-route"
                    , "flight-task"
                    , "flight-gap"
                    , "flight-mask"
                    , "flight-lookup"
                    ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "MaskTrackMain.hs"
              , source-dirs =
                  "prod-apps/mask-track"
              }
          , land-out =
              { dependencies =
                    deps
                  # [ "siggy-chardust"
                    , "flight-units"
                    , "flight-kml"
                    , "flight-track"
                    , "flight-zone"
                    , "flight-task"
                    , "flight-gap"
                    , "flight-mask"
                    ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "LandOutMain.hs"
              , source-dirs =
                  "prod-apps/land-out"
              }
          , gap-point =
              { dependencies =
                    deps
                  # [ "containers"
                    , "siggy-chardust"
                    , "flight-units"
                    , "flight-kml"
                    , "flight-track"
                    , "flight-zone"
                    , "flight-task"
                    , "flight-gap"
                    , "flight-mask"
                    ]
              , ghc-options =
                  [ "-rtsopts"
                  , "-threaded"
                  , "-with-rtsopts=-N"
                  , "-Wall"
                  , "-fplugin Data.UnitsOfMeasure.Plugin"
                  ]
              , main =
                  "GapPointMain.hs"
              , source-dirs =
                  "prod-apps/gap-point"
              }
          , test-fsdb-parser =
              { dependencies =
                  depsTest # [ "uom-plugin", "flight-fsdb", "flight-units" ]
              , ghc-options =
                  [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
              , main =
                  "FsdbMain.hs"
              , source-dirs =
                  "test-apps/fsdb-parser"
              }
          , test-igc-parser =
              { dependencies =
                  depsTest # [ "flight-igc" ]
              , ghc-options =
                  [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
              , main =
                  "IgcMain.hs"
              , source-dirs =
                  "test-apps/igc-parser"
              }
          , test-kml-parser =
              { dependencies =
                  depsTest # [ "flight-kml" ]
              , ghc-options =
                  [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
              , main =
                  "KmlMain.hs"
              , source-dirs =
                  "test-apps/kml-parser"
              }
          }
      , tests =
          { hlint =
              { dependencies =
                  [ "hlint" ]
              , ghc-options =
                  [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
              , main =
                  "HLint.hs"
              , source-dirs =
                  "test-suite-hlint"
              }
          }
      }
