module Rebalance where

import Types
import Index
import Optimize
import Data.Time
    ( Day, addGregorianMonthsClip )

-- slice an asset's price rows to only include dates in [start, end)
sliceAsset :: Day -> Day -> Asset -> Asset
sliceAsset start end asset = asset
    { rows = filter (\r -> date r >= start && date r < end) (rows asset) }

-- generate rebalancing date boundaries
-- starting from the first date in data, stepping by months
rebalanceDates :: Day -> Day -> Int -> [Day]
rebalanceDates start end monthStep = takeWhile (<= end) dates where
    dates = iterate (addGregorianMonthsClip (fromIntegral monthStep)) start

-- run a rolling optimization backtest
-- returns a single dated return series stitched together across all periods
rollingOptimize :: [Asset] -> Double -> Int -> Int -> [(Day, Double)]
rollingOptimize assets rfr lookbackMonths holdMonths =
    let allDates = map date (rows (head assets))
        start = head allDates
        end = last allDates
        rebDates = rebalanceDates start end holdMonths
        periods = zip rebDates (tail rebDates)
    in concatMap (runPeriod assets rfr lookbackMonths) periods

runPeriod :: [Asset] -> Double -> Int -> (Day, Day) -> [(Day, Double)]
runPeriod assets rfr lookbackMonths (periodStart, periodEnd) =
    let lookbackStart = addGregorianMonthsClip (fromIntegral (-lookbackMonths)) periodStart
        trainAssets = map (sliceAsset lookbackStart periodStart) assets
        optWeights = optimizeWeights trainAssets rfr
        holdAssets = map (sliceAsset periodStart periodEnd) assets
        pairs = zip holdAssets optWeights
    in blendReturnsDated pairs
