    let deps = ./../defaults.dhall

in    deps
    ⫽ ./../default-extensions.dhall
    ⫽ { name =
          "flight-lookup"
      , synopsis =
          "Hang gliding and paragliding competition data access."
      , description =
          "Lookup items for a task, for a pilot, etc."
      , category =
          "Data"
      , github =
          "blockscope/flare-timing/lookup"
      , ghc-options =
          [ "-Wall", "-fplugin Data.UnitsOfMeasure.Plugin" ]
      , dependencies =
            deps.dependencies
          # [ "aeson"
            , "bytestring"
            , "cassava"
            , "containers"
            , "directory"
            , "filemanip"
            , "filepath"
            , "lens"
            , "mtl"
            , "path"
            , "scientific"
            , "split"
            , "time"
            , "unordered-containers"
            , "uom-plugin"
            , "flight-clip"
            , "flight-comp"
            , "flight-gap"
            , "flight-kml"
            , "flight-latlng"
            , "flight-mask"
            , "flight-route"
            , "flight-zone"
            , "detour-via-sci"
            ]
      , library =
          { source-dirs =
              "library"
          , exposed-modules =
              [ "Flight.Lookup.Route"
              , "Flight.Lookup.Cross"
              , "Flight.Lookup.Tag"
              , "Flight.Lookup.Stop"
              , "Flight.Lookup"
              ]
          }
      , tests =
          ./../default-tests.dhall
      }
