module Main where

import Types
import Parse
    hiding ( mapMaybe, splitOn )
import Index
import Metrics
import System.Directory ( listDirectory ) 
import System.FilePath
    ( (</>), takeBaseName )
import Data.List ( find )

assetFolder :: FilePath
assetFolder = "assets"

indexFile :: FilePath
indexFile = "indexes.txt"

outputFile :: FilePath
outputFile = "results.csv"

main :: IO ()
main = do
  files <- listDirectory assetFolder
  assets <- mapM (\f -> do
    contents <- readFile (assetFolder </> f)
    return $ loadAsset (takeBaseName f) contents) files
  specs <- loadIndexSpecs indexFile

  -- use bonds as risk free rate
  let rfAsset = find (\a -> name a == "bonds") assets
      rfRate = case rfAsset of
        Just a -> computeAnnualizedReturn (dailyReturns (rows a))
        Nothing -> 0.02

  -- compute metrics for each index
  let results = map (computeIndex assets rfRate) specs

  -- write output csv
  writeFile outputFile (toCSV results)
  putStrLn $ "wrote " ++ outputFile

computeIndex :: [Asset] -> Double -> IndexSpec -> (String, Metrics)
computeIndex assets rfr spec =
    let pairs = mapMaybe (\(n, w) -> case find (\a -> name a == n) assets of
            Just a -> Just (a, w)
            Nothing -> Nothing) (weights spec)
        blended = blendReturns pairs
        metrics = computeMetrics blended rfr
    in (indexName spec, metrics)

toCSV :: [(String, Metrics)] -> String
toCSV entries =
    let header = "name,total_return,annualized_return,volatility,sharpe_ratio"
        lines' = map toRow entries
    in unlines (header : lines')

toRow :: (String, Metrics) -> String
toRow (n, m) = n ++ ","
    ++ show (totalReturn m) ++ ","
    ++ show (annualizedReturn m) ++ ","
    ++ show (volatility m) ++ ","
    ++ show (sharpeRatio m)
