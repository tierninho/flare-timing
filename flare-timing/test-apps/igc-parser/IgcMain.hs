import System.Environment (getProgName)
import System.Console.CmdArgs.Implicit (cmdArgs)
import Control.Monad (mapM_)
import System.FilePath (takeFileName)

import Flight.Cmd.Paths (LenientFile(..), checkPaths)
import Flight.Igc (parseFromFile)
import Flight.Comp (IgcFile(..), findIgc)
import IgcOptions (IgcOptions(..), mkOptions)

main :: IO ()
main = do
    name <- getProgName
    options <- cmdArgs $ mkOptions name

    let lf = LenientFile {coerceFile = id}
    err <- checkPaths lf options

    maybe (drive options) putStrLn err

drive :: IgcOptions -> IO ()
drive o = do
    files <- findIgc o
    if null files then putStrLn "Couldn't find any input files."
                  else mapM_ go files

go :: IgcFile -> IO ()
go (IgcFile path) = do
    putStrLn $ takeFileName path
    p <- parseFromFile path
    either print print p
