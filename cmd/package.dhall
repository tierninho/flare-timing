    let defs = ./../defaults.dhall

in    defs
    ⫽ ./../default-extensions.dhall
    ⫽ { name =
          "flight-cmd"
      , synopsis =
          "Command line options."
      , description =
          "Command line options such as file or directory, task or pilot."
      , category =
          "Flight"
      , github =
          "blockscope/flare-timing/cmd"
      , dependencies =
            defs.dependencies
          # [ "directory"
            , "filepath"
            , "filemanip"
            , "raw-strings-qq"
            , "cmdargs"
            , "mtl"
            , "transformers"
            , "flight-span"
            ]
      , library =
          { source-dirs =
              "library"
          , exposed-modules =
              [ "Flight.Cmd.Options"
              , "Flight.Cmd.BatchOptions"
              , "Flight.Cmd.ServeOptions"
              , "Flight.Cmd.Paths"
              ]
          }
      , tests =
          ./../default-tests.dhall
      }
