module Index where

import Types
import Data.List ( sortBy )
import Data.Ord ( comparing )

-- parse a single line like "my_index, sp500 0.5, gold 0.5"
parseIndexSpec :: String -> Maybe IndexSpec
parseIndexSpec line = case splitOn ',' line of
    (n:ws) -> case mapMaybe parseWeight ws of
        [] -> Nothing
        xs -> Just $ IndexSpec (trim n) xs
    _ -> Nothing

parseWeight :: String -> Maybe (String, Double)
parseWeight s = case words (trim s) of
    [n, w] -> (case reads w of
        [(v, "")] -> Just (n, v)
        _ -> Nothing)
    _ -> Nothing

loadIndexSpecs :: FilePath -> IO [IndexSpec]
loadIndexSpecs fp = do
    contents <- readFile fp
    return $ mapMaybe parseIndexSpec (lines contents)

-- align two price series on common dates
alignDates :: [PriceRow] -> [PriceRow] -> [(PriceRow, PriceRow)]
alignDates [] _ = []
alignDates _ [] = []
alignDates (a:as) (b:bs)
    | date a == date b = (a, b) : alignDates as bs
    | date a < date b = alignDates as (b:bs)
    | otherwise = alignDates (a:as) bs

-- compute daily returns from a price series
dailyReturns :: [PriceRow] -> [Double]
dailyReturns [] = []
dailyReturns [_] = []
dailyReturns (a:b:rest) = (close b - close a) / close a : dailyReturns (b:rest)

-- blend multiple assets into a single daily return series by weight
blendReturns :: [(Asset, Double)] -> [Double]
blendReturns [] = []
blendReturns pairs =
    let sorted = map (\(a, w) -> (sortBy (comparing date) (rows a), w)) pairs
        returnSeries = map (\(rs, w) -> map (* w) (dailyReturns rs)) sorted
        minLen = minimum (map length returnSeries)
        trimmed = map (take minLen) returnSeries
    in foldr1 (zipWith (+)) trimmed

-- trim helper
trim :: String -> String
trim = reverse . dropWhile (== ' ') . reverse . dropWhile (== ' ')

-- mapMaybe since we can't import it here
mapMaybe :: (a -> Maybe b) -> [a] -> [b]
mapMaybe _ [] = []
mapMaybe f (x:xs) = case f x of
    Just y -> y : mapMaybe f xs
    Nothing -> mapMaybe f xs

splitOn :: Char -> String -> [String]
splitOn _ "" = [""]
splitOn c (x:xs)
    | x == c = "" : splitOn c xs
    | otherwise = case splitOn c xs of
        (h:t) -> (x:h) : t
        [] -> [[x]]
