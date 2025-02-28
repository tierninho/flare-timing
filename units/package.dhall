    let defs = ./../defaults.dhall

in    defs
    ⫽ ./../default-extensions.dhall
    ⫽ { name =
          "flight-units"
      , synopsis =
          "Units used in hang gliding and paragliding competitions."
      , description =
          "Unit definitions such as m, km, rad and deg."
      , category =
          "Flight"
      , github =
          "blockscope/flare-timing/units"
      , ghc-options =
          [ "-Wall", "-fplugin Data.UnitsOfMeasure.Plugin" ]
      , dependencies =
            defs.dependencies
          # [ "numbers"
            , "fixed"
            , "bifunctors"
            , "text"
            , "formatting"
            , "uom-plugin"
            , "siggy-chardust"
            , "detour-via-sci"
            , "newtype"
            ]
      , library =
          { source-dirs =
              "library"
          , exposed-modules =
              [ "Flight.Ratio"
              , "Flight.Units"
              , "Flight.Units.Angle"
              , "Flight.Units.DegMinSec"
              ]
          }
      , tests =
          ./../default-tests.dhall
      }
