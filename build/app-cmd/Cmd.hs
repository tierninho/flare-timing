module Cmd (buildRules, cleanRules, testRules, lintRules) where

import Development.Shake
    ( Rules
    , CmdOption(Shell, Cwd)
    , removeFilesAfter
    , phony
    , cmd
    , need
    )

cmdTestFor :: String -> String
cmdTestFor x =
    "stack test " ++ x

cmdBuildFor :: String -> String
cmdBuildFor x =
    "stack build " ++ x ++ " --copy-bins"

-- | The names of the hlint tests
lintPkgs :: [String]
lintPkgs =
    [ "units"
    , "zone"
    , "track"
    , "task"
    , "mask"
    , "latlng"
    , "fsdb"
    , "igc"
    , "kml"
    , "comp"
    ] 

type Pkg = String
type Test = String

-- | The pairs are names of the pkg and test.
testPkgs :: [(Pkg, Test)]
testPkgs =
    [ ("task", "task")
    , ("kml", "parse")
    , ("fsdb", "parse")
    , ("gap", "score")
    ] 

-- | The names of the test app executables
testApps :: [String]
testApps =
    [ "test-fsdb-parser"
    , "test-igc-parser"
    , "test-kml-parser"
    ] 

-- | The names of the production app executables
prodApps :: [String]
prodApps =
    [ "extract-task"
    , "task-length"
    , "cross-zone"
    , "tag-zone"
    , "align-time"
    , "filter-time"
    , "mask-track"
    , "comp-serve"
    ] 

cleanRules :: Rules ()
cleanRules = do
    phony "clean-prod-apps" $
        removeFilesAfter "__shake-build" prodApps

    phony "clean-test-apps" $
        removeFilesAfter "__shake-build" testApps

prefix :: String -> String -> String
prefix prefix' s = prefix' ++ s

lintRule :: String -> Rules ()
lintRule s =
    phony ("lint-" ++ s) $
        cmd
            (Cwd s) 
            Shell
            (cmdTestFor "flight-" ++ s ++ ":hlint")

lintRules :: Rules ()
lintRules = do
    _ <- sequence $ lintRule <$> lintPkgs

    phony "lint" $ need
        $ "lint-build"
        : "lint-flare-timing"
        : (prefix "lint-" <$> lintPkgs)

    phony "lint-build" $
        cmd
            (Cwd "build")
            Shell
            (cmdTestFor "build-flare-timing:hlint")

    phony "lint-flare-timing" $
        cmd
            (Cwd "flare-timing")
            Shell
            (cmdTestFor "flare-timing:hlint")

testRule :: (Pkg, Test) -> Rules ()
testRule (pkg, test) =
    phony ("test-" ++ pkg) $
        cmd
            (Cwd pkg)
            Shell
            (cmdTestFor $ "flight-" ++ pkg ++":" ++ test)

testRules :: Rules ()
testRules = do
    _ <- sequence $ testRule <$> testPkgs
    phony "test" $ need $ prefix "test-" . fst <$> testPkgs

buildRule :: String -> Rules ()
buildRule s =
    phony s $
        cmd
            (Cwd "flare-timing")
            Shell
            (cmdBuildFor $ "flare-timing:" ++ s)

buildRules :: Rules ()
buildRules = do
    _ <- sequence $ buildRule <$> (testApps ++ prodApps)
    phony "test-apps" $ need testApps
    phony "prod-apps" $ need prodApps
