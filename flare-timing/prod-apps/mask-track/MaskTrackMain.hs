﻿{-# OPTIONS_GHC -fplugin Data.UnitsOfMeasure.Plugin #-}
{-# OPTIONS_GHC -fno-warn-partial-type-signatures #-}

import System.Environment (getProgName)
import System.Console.CmdArgs.Implicit (cmdArgs)
import Formatting ((%), fprint)
import Formatting.Clock (timeSpecs)
import System.Clock (getTime, Clock(Monotonic))
import Control.Exception.Safe (catchIO)
import System.FilePath (takeFileName)

import Flight.Route (OptimalRoute(..))
import Flight.Comp
    ( FileType(CompInput)
    , CompInputFile(..)
    , TaskLengthFile(..)
    , TagZoneFile(..)
    , PegFrameFile(..)
    , PilotName(..)
    , IxTask(..)
    , compToTaskLength
    , compToCross
    , crossToTag
    , tagToPeg
    , findCompInput
    , ensureExt
    , pilotNamed
    )
import Flight.Cmd.Paths (LenientFile(..), checkPaths)
import Flight.Cmd.Options (ProgramName(..))
import Flight.Cmd.BatchOptions (CmdBatchOptions(..), mkOptions)
import Flight.Lookup.Stop (stopFlying)
import Flight.Lookup.Tag (tagTaskLeading)
import Flight.Scribe (readComp, readRoute, readTagging, readFraming)
import Flight.Lookup.Route (routeLength)
import MaskTrackOptions (description)
import Mask.Mask (writeMask, check)

main :: IO ()
main = do
    name <- getProgName
    options <- cmdArgs $ mkOptions (ProgramName name) description Nothing

    let lf = LenientFile {coerceFile = ensureExt CompInput}
    err <- checkPaths lf options

    maybe (drive options) putStrLn err

drive :: CmdBatchOptions -> IO ()
drive o = do
    -- SEE: http://chrisdone.com/posts/measuring-duration-in-haskell
    start <- getTime Monotonic
    files <- findCompInput o
    if null files then putStrLn "Couldn't find any input files."
                  else mapM_ (go o) files
    end <- getTime Monotonic
    fprint ("Masking tracks completed in " % timeSpecs % "\n") start end

go :: CmdBatchOptions -> CompInputFile -> IO ()
go CmdBatchOptions{..} compFile@(CompInputFile compPath) = do
    let lenFile@(TaskLengthFile lenPath) = compToTaskLength compFile
    let tagFile@(TagZoneFile tagPath) = crossToTag . compToCross $ compFile
    let stopFile@(PegFrameFile stopPath) = tagToPeg tagFile
    putStrLn $ "Reading competition from '" ++ takeFileName compPath ++ "'"
    putStrLn $ "Reading task length from '" ++ takeFileName lenPath ++ "'"
    putStrLn $ "Reading zone tags from '" ++ takeFileName tagPath ++ "'"
    putStrLn $ "Reading scored times from '" ++ takeFileName stopPath ++ "'"

    compSettings <-
        catchIO
            (Just <$> readComp compFile)
            (const $ return Nothing)

    tagging <-
        catchIO
            (Just <$> readTagging tagFile)
            (const $ return Nothing)

    stopping <-
        catchIO
            (Just <$> readFraming stopFile)
            (const $ return Nothing)

    routes <-
        catchIO
            (Just <$> readRoute lenFile)
            (const $ return Nothing)

    let scoredLookup = stopFlying stopping
    let lookupTaskLength = routeLength taskRoute taskRouteSpeedSubset stopRoute routes

    case (compSettings, tagging, stopping, routes) of
        (Nothing, _, _, _) -> putStrLn "Couldn't read the comp settings."
        (_, Nothing, _, _) -> putStrLn "Couldn't read the taggings."
        (_, _, Nothing, _) -> putStrLn "Couldn't read the scored frame."
        (_, _, _, Nothing) -> putStrLn "Couldn't read the routes."
        (Just cs, Just _, Just _, Just _) ->
            writeMask
                math
                cs
                lookupTaskLength
                (tagTaskLeading tagging)
                (IxTask <$> task)
                (pilotNamed cs $ PilotName <$> pilot)
                compFile
                (check math lookupTaskLength scoredLookup tagging)
