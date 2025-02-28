    let defs = ./../defaults.dhall

in    defs
    ⫽ ./../default-extensions.dhall
    ⫽ { name =
          "flight-earth"
      , synopsis =
          "Distances on the WGS84 ellipsoid, the FAI sphere and the UTM projection."
      , description =
          "Distances on the Earth for hang gliding and paragliding competitons."
      , category =
          "Flight"
      , github =
          "blockscope/flare-timing/earth"
      , ghc-options =
          [ "-Wall", "-fplugin Data.UnitsOfMeasure.Plugin" ]
      , dependencies =
            defs.dependencies
          # [ "numbers"
            , "fgl"
            , "uom-plugin"
            , "bifunctors"
            , "aeson"
            , "scientific"
            , "mtl"
            , "hcoord"
            , "hcoord-utm"
            , "detour-via-sci"
            , "detour-via-uom"
            , "siggy-chardust"
            , "flight-latlng"
            , "flight-units"
            , "flight-zone"
            ]
      , library =
          { source-dirs =
              "library"
          , exposed-modules =
              [ "Flight.Earth.Flat.Projected.Double"
              , "Flight.Earth.Flat.Projected.Rational"
              , "Flight.Earth.Flat.Separated"
              , "Flight.Earth.Flat"
              , "Flight.Earth.Sphere.Cylinder.Double"
              , "Flight.Earth.Sphere.Cylinder.Rational"
              , "Flight.Earth.Sphere.PointToPoint.Double"
              , "Flight.Earth.Sphere.PointToPoint.Rational"
              , "Flight.Earth.Sphere.Separated"
              , "Flight.Earth.Sphere"
              , "Flight.Earth.Ellipsoid.Cylinder.Double"
              , "Flight.Earth.Ellipsoid.Cylinder.Rational"
              , "Flight.Earth.Ellipsoid.PointToPoint.Double"
              , "Flight.Earth.Ellipsoid.PointToPoint.Rational"
              , "Flight.Earth.Ellipsoid.Separated"
              , "Flight.Earth.Ellipsoid"
              , "Flight.Earth.Geodesy"
              ]
          }
      , tests =
            ./../default-tests.dhall
          ⫽ { earth =
                { dependencies =
                    [ "tasty"
                    , "tasty-hunit"
                    , "tasty-quickcheck"
                    , "tasty-smallcheck"
                    , "smallcheck"
                    , "tasty-compare"
                    ]
                , ghc-options =
                    [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
                , main =
                    "Earth.hs"
                , source-dirs =
                    [ "library", "test-suite-earth" ]
                }
            , doctest =
                { dependencies =
                    [ "doctest" ]
                , ghc-options =
                    [ "-rtsopts", "-threaded", "-with-rtsopts=-N" ]
                , main =
                    "DocTest.hs"
                , source-dirs =
                    [ "library", "test-suite-doctest" ]
                }
            }
      }
