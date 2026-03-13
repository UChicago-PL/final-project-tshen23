module Optimize where

import Types
import Index
import Metrics
import Data.List ( maximumBy )
import Data.Ord ( comparing )

-- generate all weight combinations for n assets that sum to 1
-- using 0.1 step size
weightCombinations :: Int -> [[Double]]
weightCombinations n = filter sumToOne (sequence (replicate n steps)) where
    steps = [0.0, 0.1 .. 1.0]
    sumToOne ws = abs (sum ws - 1.0) < 1e-9

-- compute sharpe for a given set of assets and weights
-- over a specific date range
sharpeForWeights :: [Asset] -> [Double] -> Double -> Double
sharpeForWeights assets ws rfr =
    let pairs = zip assets ws
        dated = blendReturnsDated pairs
        returns = map snd dated
    in if length returns < 2
       then -99999
       else computeSharpe returns rfr

-- brute force finding the optimal weights for a list of assets by
-- using grid search over all combinations
optimizeWeights :: [Asset] -> Double -> [Double]
optimizeWeights assets rfr =
    let n = length assets
        combos = weightCombinations n
        scored = map (\ws -> (ws, sharpeForWeights assets ws rfr)) combos
    in fst $ maximumBy (comparing snd) scored