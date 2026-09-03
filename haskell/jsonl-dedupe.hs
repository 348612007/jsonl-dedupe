#!/usr/bin/env stack
-- stack script --resolver lts-20.20 --package aeson --package bytestring --package text --package unordered-containers --package scientific

{-# LANGUAGE OverloadedStrings #-}

-- jsonl-dedupe.hs
-- 简单 JSONL 去重：按指定顶层键去重（默认 "id").
-- 用法:
--   stack runghc jsonl-dedupe.hs [input.jsonl] [key]
-- 或（从 stdin）:
--   cat data.jsonl | stack runghc jsonl-dedupe.hs - id

import qualified Data.ByteString.Lazy.Char8 as BL
import qualified Data.ByteString as BS
import Data.Aeson (decode, Value(..), encode)
import qualified Data.Aeson.KeyMap as KM
import Data.Aeson.Key (fromString)
import Data.Text (Text)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.HashSet as HS
import System.Environment (getArgs)
import System.IO (stderr, hPutStrLn)
import Data.Scientific (formatScientific, FPFormat(..))
import Control.Monad (when)
import Data.Maybe (fromMaybe)

-- Convert a JSON Value to a textual representation for dedupe key comparison
valueToText :: Value -> Text
valueToText (String s) = s
valueToText (Number n) = T.pack $ formatScientific Generic Nothing n
valueToText (Bool True) = "true"
valueToText (Bool False) = "false"
valueToText Null = "null"
valueToText v = TE.decodeUtf8 . BL.toStrict $ encode v

main :: IO ()
main = do
  args <- getArgs
  let (inputPath, key) = case args of
        (p:k:_) -> (p, k)
        (p:_)   -> (p, "id")
        []      -> ("-", "id")
  contents <- if inputPath == "-" then BL.getContents else BL.readFile inputPath
  let linesBS = BL.split '\n' contents
  _ <- process linesBS (T.pack key) HS.empty 1 0
  return ()

-- process lines recursively, carrying seen set and counters:
-- args: remaining lines, key, seen-set, lineNo, warnCount
process :: [BL.ByteString] -> Text -> HS.HashSet Text -> Int -> Int -> IO (HS.HashSet Text, Int)
process [] _ seen ln wc = return (seen, wc)
process (ln:rest) key seen lineNo warnCount
  | BL.null ln || BL.all (`elem` ("\r\n"::String)) ln = process rest key seen (lineNo+1) warnCount
  | otherwise =
      case decode ln :: Maybe Value of
        Nothing -> do
          let wc' = warnCount + 1
          when (warnCount < 5) $
            hPutStrLn stderr $ "warn: failed to parse JSON on line " ++ show lineNo ++ " -- emitting raw line"
          BL.putStrLn ln
          process rest key seen (lineNo+1) wc'
        Just (Object obj) ->
          let m = KM.lookup (fromString (T.unpack key)) obj in
          case m of
            Nothing -> do
              when (lineNo `mod` 1000 == 1) $
                hPutStrLn stderr $ "warn: key '" ++ T.unpack key ++ "' not found in line " ++ show lineNo
              BL.putStrLn ln
              process rest key seen (lineNo+1) warnCount
            Just v ->
              let idtxt = valueToText v in
              if HS.member idtxt seen
                then process rest key seen (lineNo+1) warnCount
                else do
                  BL.putStrLn ln
                  process rest key (HS.insert idtxt seen) (lineNo+1) warnCount
        Just _other -> do
          -- parsed JSON but not an object (e.g. array/number) — emit and warn once
          when (warnCount < 5) $
            hPutStrLn stderr $ "warn: non-object JSON on line " ++ show lineNo ++ " -- emitting raw line"
          let wc' = warnCount + 1
          BL.putStrLn ln
          process rest key seen (lineNo+1) wc'
