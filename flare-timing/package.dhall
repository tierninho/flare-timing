  ./defaults.dhall 
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
              [ "base"
              , "directory"
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
              , "containers"
              , "uom-plugin"
              , "flight-cmd"
              , "flight-latlng"
              , "flight-gap"
              , "flight-comp"
              , "flight-fsdb"
              , "flight-scribe"
              ]
          , ghc-options =
              [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
          , main =
              "ExtractInputMain.hs"
          , source-dirs =
              "prod-apps/extract-input"
          }
      , task-length =
          { dependencies =
              [ "base"
              , "directory"
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
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-task"
              , "flight-route"
              , "flight-scribe"
              ]
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
              [ "base"
              , "directory"
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
              , "lens"
              , "siggy-chardust"
              , "flight-span"
              , "flight-cmd"
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-kml"
              , "flight-track"
              , "flight-zone"
              , "flight-earth"
              , "flight-task"
              , "flight-gap"
              , "flight-mask"
              , "flight-scribe"
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
              [ "base"
              , "directory"
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
              , "time"
              , "formatting"
              , "siggy-chardust"
              , "flight-cmd"
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-kml"
              , "flight-track"
              , "flight-task"
              , "flight-gap"
              , "flight-mask"
              , "flight-scribe"
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
              [ "base"
              , "directory"
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
              , "time"
              , "formatting"
              , "cassava"
              , "vector"
              , "split"
              , "lens"
              , "siggy-chardust"
              , "flight-cmd"
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-kml"
              , "flight-track"
              , "flight-zone"
              , "flight-task"
              , "flight-gap"
              , "flight-mask"
              , "flight-lookup"
              , "flight-scribe"
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
              [ "base"
              , "directory"
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
              , "time"
              , "formatting"
              , "cassava"
              , "vector"
              , "split"
              , "siggy-chardust"
              , "flight-cmd"
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-kml"
              , "flight-track"
              , "flight-zone"
              , "flight-route"
              , "flight-task"
              , "flight-gap"
              , "flight-mask"
              , "flight-lookup"
              , "flight-scribe"
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
              [ "base"
              , "directory"
              , "filepath"
              , "system-filepath"
              , "filemanip"
              , "raw-strings-qq"
              , "cmdargs"
              , "lens"
              , "mtl"
              , "monadplus"
              , "transformers"
              , "yaml"
              , "aeson"
              , "uom-plugin"
              , "bytestring"
              , "clock"
              , "formatting"
              , "numbers"
              , "time"
              , "vector"
              , "containers"
              , "siggy-chardust"
              , "flight-span"
              , "flight-cmd"
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-kml"
              , "flight-track"
              , "flight-zone"
              , "flight-route"
              , "flight-task"
              , "flight-gap"
              , "flight-mask"
              , "flight-lookup"
              , "flight-scribe"
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
              [ "base"
              , "directory"
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
              , "siggy-chardust"
              , "flight-cmd"
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-kml"
              , "flight-track"
              , "flight-zone"
              , "flight-task"
              , "flight-gap"
              , "flight-mask"
              , "flight-scribe"
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
              [ "base"
              , "directory"
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
              , "time"
              , "formatting"
              , "containers"
              , "siggy-chardust"
              , "flight-cmd"
              , "flight-units"
              , "flight-latlng"
              , "flight-comp"
              , "flight-kml"
              , "flight-track"
              , "flight-zone"
              , "flight-task"
              , "flight-gap"
              , "flight-mask"
              , "flight-scribe"
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
              [ "base"
              , "directory"
              , "filepath"
              , "system-filepath"
              , "filemanip"
              , "raw-strings-qq"
              , "cmdargs"
              , "mtl"
              , "transformers"
              , "uom-plugin"
              , "flight-cmd"
              , "flight-comp"
              , "flight-fsdb"
              , "flight-units"
              ]
          , ghc-options =
              [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
          , main =
              "FsdbMain.hs"
          , source-dirs =
              "test-apps/fsdb-parser"
          }
      , test-igc-parser =
          { dependencies =
              [ "base"
              , "directory"
              , "filepath"
              , "system-filepath"
              , "filemanip"
              , "raw-strings-qq"
              , "cmdargs"
              , "mtl"
              , "transformers"
              , "flight-cmd"
              , "flight-igc"
              , "flight-comp"
              ]
          , ghc-options =
              [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
          , main =
              "IgcMain.hs"
          , source-dirs =
              "test-apps/igc-parser"
          }
      , test-kml-parser =
          { dependencies =
              [ "base"
              , "directory"
              , "filepath"
              , "system-filepath"
              , "filemanip"
              , "raw-strings-qq"
              , "cmdargs"
              , "mtl"
              , "transformers"
              , "flight-cmd"
              , "flight-kml"
              , "flight-comp"
              ]
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
              [ "base", "hlint" ]
          , ghc-options =
              [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
          , main =
              "HLint.hs"
          , source-dirs =
              "test-suite-hlint"
          }
      }
  }
