module Metrics where

import Types

-- total return from a daily return series
computeTotalReturn :: [Double] -> Double
computeTotalReturn = foldl (\acc r -> acc * (1 + r)) 1.0

-- annualized return given total return and number of trading days
computeAnnualizedReturn :: [Double] -> Double
computeAnnualizedReturn rs =
    let n = fromIntegral (length rs)
        total = computeTotalReturn rs
    in total ** (252 / n) - 1

-- standard deviation of daily returns (volatility)
computeVolatility :: [Double] -> Double
computeVolatility rs =
    let n = fromIntegral (length rs)
        mean = sum rs / n
        var = sum (map (\r -> (r - mean) ** 2) rs) / (n - 1)
    in sqrt var * sqrt 252

-- sharpe ratio
computeSharpe :: [Double] -> Double -> Double
computeSharpe rs riskFreeRate =
    let annRet = computeAnnualizedReturn rs
        vol = computeVolatility rs
    in (annRet - riskFreeRate) / vol

computeMetrics :: [Double] -> Double -> Metrics
computeMetrics rs rfr = Metrics
    { totalReturn = computeTotalReturn rs - 1
    , annualizedReturn = computeAnnualizedReturn rs
    , volatility = computeVolatility rs
    , sharpeRatio = computeSharpe rs rfr
    }