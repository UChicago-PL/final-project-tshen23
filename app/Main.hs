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
import Visualize
import Data.Time ( Day )
import Rebalance

assetFolder :: FilePath
assetFolder = "assets"

indexFile :: FilePath
indexFile = "indexes.txt"

outputFile :: FilePath
outputFile = "results.csv"

chartFile :: FilePath
chartFile = "performance.svg"

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
        results = map (computeIndex assets rfRate) specs
        datedSeries = map (computeDatedSeries assets rfRate) specs
    

    -- write output csv
    writeFile outputFile (toCSV results)
    putStrLn $ "wrote " ++ outputFile

    -- render chart
    renderChart chartFile datedSeries
    putStrLn $ "wrote " ++ chartFile

computeIndex :: [Asset] -> Double -> IndexSpec -> (String, Metrics)
computeIndex assets rfr (ManualIndex n ws) =
    let pairs = mapMaybe (\(nm, w) -> case find (\a -> name a == nm) assets of
            Just a -> Just (a, w)
            Nothing -> Nothing) ws
        blended = blendReturns pairs
    in (n, computeMetrics blended rfr)
computeIndex assets rfr (SharpeIndex n lb hm) =
    let series = rollingOptimize assets rfr lb hm
    in (n, computeMetrics (map snd series) rfr)

computeDatedSeries :: [Asset] -> Double -> IndexSpec -> (String, [(Day, Double)])
computeDatedSeries assets _ (ManualIndex n ws) =
    let pairs = mapMaybe (\(nm, w) -> case find (\a -> name a == nm) assets of
            Just a -> Just (a, w)
            Nothing -> Nothing) ws
    in (n, blendReturnsDated pairs)
computeDatedSeries assets rfr (SharpeIndex n lb hm) =
    (n, rollingOptimize assets rfr lb hm)

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
