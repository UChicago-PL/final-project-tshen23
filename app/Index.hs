module Index where

import Types
import Data.List ( sortBy )
import Data.Ord ( comparing )
import Data.Time ( Day )

-- parse a single line like "my_index, sp500 0.5, gold 0.5"
parseIndexSpec :: String -> Maybe IndexSpec
parseIndexSpec line = case words line of
    [n, "sharpe", lb, hm] -> case (reads lb, reads hm) of
        ([(lbv, "")], [(hmv, "")]) -> Just $ SharpeIndex n lbv hmv
        _ -> Nothing
    _ -> case splitOn ',' line of
        (n:ws) -> case mapMaybe parseWeight ws of
            [] -> Nothing
            xs -> Just $ ManualIndex (trim n) xs
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

-- blendReturns but keeps dates for charts
blendReturnsDated :: [(Asset, Double)] -> [(Day, Double)]
blendReturnsDated [] = []
blendReturnsDated pairs =
    let sorted = map (\(a, w) -> (sortBy (comparing date) (rows a), w)) pairs
        dates = map date (fst (head sorted))
        returns = map (\(rs, w) -> map (* w) (dailyReturns rs)) sorted
        minLen = minimum (map length returns)
        trimmed = map (take minLen) returns
        blended = foldr1 (zipWith (+)) trimmed
    in zip (drop 1 (take (minLen + 1) dates)) blended

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
