import System.Environment (getProgName)
import System.Console.CmdArgs.Implicit (cmdArgs)
import Formatting ((%), fprint)
import Formatting.Clock (timeSpecs)
import System.Clock (getTime, Clock(Monotonic))
import Data.Maybe (catMaybes)
import Data.List (sortOn)
import qualified Data.Map.Strict as Map (fromList, lookup)
import Control.Arrow (second)
import Control.Monad (mapM_)
import Control.Monad.Except (ExceptT(..), runExceptT, lift)
import Data.UnitsOfMeasure (u)
import Data.UnitsOfMeasure.Internal (Quantity(..))

import Flight.Cmd.Paths (LenientFile(..), checkPaths)
import Flight.Cmd.Options (ProgramName(..))
import Flight.Cmd.BatchOptions (CmdBatchOptions(..), mkOptions)
import Flight.Fsdb (parseScores)
import Flight.Track.Speed (TrackSpeed)
import qualified Flight.Track.Speed as Track (TrackSpeed(..))
import Flight.Track.Point (NormPointing(..), NormBreakdown(..))
import Flight.Comp
    ( FileType(Fsdb)
    , FsdbFile(..)
    , FsdbXml(..)
    , Pilot(..)
    , fsdbToScore
    , findFsdb
    , ensureExt
    )
import qualified Flight.Score as Gap (bestTime')
import Flight.Score (BestTime(..), PilotTime(..), speedFraction)
import Flight.Scribe (writeScore)
import FsScoreOptions (description)

main :: IO ()
main = do
    name <- getProgName
    options <- cmdArgs $ mkOptions (ProgramName name) description Nothing

    let lf = LenientFile {coerceFile = ensureExt Fsdb}
    err <- checkPaths lf options

    maybe (drive options) putStrLn err

drive :: CmdBatchOptions -> IO ()
drive o = do
    -- SEE: http://chrisdone.com/posts/measuring-duration-in-haskell
    start <- getTime Monotonic
    files <- findFsdb o

    if null files then putStrLn "Couldn't find any input files."
                  else mapM_ go files
    end <- getTime Monotonic
    fprint ("Extracting expected or normative scores completed in " % timeSpecs % "\n") start end

go :: FsdbFile -> IO ()
go fsdbFile@(FsdbFile fsdbPath) = do
    contents <- readFile fsdbPath
    let contents' = dropWhile (/= '<') contents
    settings <- runExceptT $ normScores (FsdbXml contents')
    either print (writeScore (fsdbToScore fsdbFile)) settings

fsdbScores :: FsdbXml -> ExceptT String IO NormPointing
fsdbScores (FsdbXml contents) = do
    fs <- lift $ parseScores contents
    ExceptT $ return fs

normScores :: FsdbXml -> ExceptT String IO NormPointing
normScores fsdbXml = do
    NormPointing{score = xss} <- fsdbScores fsdbXml

    let vss :: [Maybe (BestTime (Quantity Double [u| h |]), [(Pilot, TrackSpeed)])] =
            times <$> xss

    let ts = (fmap . fmap) fst vss

    let yss =
            [
                reverse . sortOn (total . snd) $
                maybe
                    xs
                    (\vs' ->
                        let vMap = Map.fromList vs' in
                        [
                            case Map.lookup p vMap of
                                Nothing -> px
                                Just
                                    Track.TrackSpeed
                                        { Track.time = tt
                                        , Track.frac = tf
                                        } -> (p, x{timeElapsed = Just tt, timeFrac = tf})
                        | px@(p, x) <- xs
                        ])
                    vs

            | xs <- xss
            | vs <- (fmap . fmap) snd vss
            ]

    return $ NormPointing{bestTime = ts, score = yss}

times
    :: [(Pilot, NormBreakdown)]
    -> Maybe (BestTime (Quantity Double [u| h |]), [(Pilot, TrackSpeed)])
times xs =
    (\ bt -> (bt, second (g bt) <$> ys))
    <$> Gap.bestTime' ts
    where
        ys :: [(Pilot, PilotTime (Quantity Double [u| h |]))]
        ys =
            catMaybes
            $ (\(p, NormBreakdown{timeElapsed = t}) -> (p,) <$> t)
            <$> xs

        ts :: [PilotTime (Quantity Double [u| h |])]
        ts = snd <$> ys

        g best t =
            Track.TrackSpeed
                { Track.time = t
                , Track.frac = speedFraction best t
                }
