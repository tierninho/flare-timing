{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE DeriveGeneric #-}

module Cmd.Driver (driverMain) where

import Control.Monad (mapM_)
import System.Directory (doesFileExist, doesDirectoryExist)
import System.FilePath (takeFileName)
import System.FilePath.Find
    (FileType(..), (==?), (&&?), find, always, fileType, extension)
import System.FilePath (replaceExtension)

import Cmd.Args (withCmdArgs)
import Cmd.Options (CmdOptions(..))
import Data.Flight.Types (Task(..))
import Data.Flight.Nominal (Nominal(..))
import Data.Flight.Comp (Comp(..))
import qualified Data.Flight.Comp as C (parse)
import qualified Data.Flight.Nominal as N (parse)
import qualified Data.Flight.Waypoint as W (parse)
import Data.Flight.Pilot
    ( Pilot(..)
    , PilotTrackLogFile(..)
    , parseNames
    , parseTracks
    , parseTaskFolders
    )
import qualified Data.Yaml.Pretty as Y
import GHC.Generics (Generic)
import Data.Aeson (ToJSON(..), FromJSON(..))
import qualified Data.ByteString as BS

data CompSettings =
    CompSettings { comp :: Comp
                 , nominal :: Nominal
                 , tasks :: [Task]
                 } deriving (Show, Generic)

instance ToJSON CompSettings
instance FromJSON CompSettings

driverMain :: IO ()
driverMain = withCmdArgs drive

drive :: CmdOptions -> IO ()
drive CmdOptions{..} = do
    dfe <- doesFileExist file
    if dfe then
        go file
    else do
        dde <- doesDirectoryExist dir
        if dde then do
            files <- find always (fileType ==? RegularFile &&? extension ==? ".fsdb") dir
            mapM_ go files
        else
            putStrLn "Couldn't find any flight score competition database input files."
    where
        go path = do
            putStrLn $ takeFileName path
            contents <- readFile path
            let contents' = dropWhile (/= '<') contents
            let path' = replaceExtension path ".yaml"

            printNominal path' contents'

printNominal :: FilePath -> String -> IO ()
printNominal path contents = do
    cs <- C.parse contents
    ns <- N.parse contents
    ws <- W.parse contents
    case (cs, ns, ws) of
        (Left msg, _, _) -> print msg
        (_, Left msg, _) -> print msg
        (_, _, Left msg) -> print msg

        (Right [c], Right [n], Right w) -> do
            let cfg =
                    CompSettings { comp = c
                                 , nominal = n
                                 , tasks = w
                                 }

            let yaml =
                    Y.encodePretty
                        (Y.setConfCompare cmp Y.defConfig)
                        cfg

            BS.writeFile path yaml

        _ -> print $ ("Expected only one set of inputs" :: String)

    where
        cmp a b =
            case (a, b) of
                -- CompSettings fields
                ("comp", _) -> LT
                ("nominal", "comp") -> GT
                ("nominal", _) -> LT
                -- Comp fields
                ("compName", _) -> LT
                ("location", "compName") -> GT
                ("location", _) -> LT
                ("from", "to") -> LT
                ("civilId", "utcOffset") -> LT
                ("civilId", _) -> GT
                ("utcOffset", _) -> GT
                -- Task fields
                ("taskName", _) -> LT
                ("zones", "taskName") -> GT
                ("zones", _) -> LT
                ("speedSection", _) -> GT
                -- Turnpoint fields
                ("zoneName", _) -> LT
                ("lat", "zoneName") -> GT
                ("lat", _) -> LT
                ("lng", "zoneName") -> GT
                ("lng", "lat") -> GT
                ("lng", _) -> LT
                ("radius", _) -> GT
                _ -> compare a b
