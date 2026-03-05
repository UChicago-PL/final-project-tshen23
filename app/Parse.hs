module Parse where

import Types
import Data.Time
    ( parseTimeM, defaultTimeLocale )

-- drop the 3 header rows yfinance adds
stripHeaders :: [String] -> [String]
stripHeaders = drop 3

parseRow :: String -> Maybe PriceRow
parseRow line = case splitOn ',' line of
    (d:c:_) -> case parseTimeM True defaultTimeLocale "%Y-%m-%d" d of
        Just day -> case reads c of
            [(v, "")] -> Just $ PriceRow day v
            _ -> Nothing
        Nothing -> Nothing
    _ -> Nothing

splitOn :: Char -> String -> [String]
splitOn _ "" = [""]
splitOn c (x:xs)
    | x == c = "" : splitOn c xs
    | otherwise = case splitOn c xs of
        (h:t) -> (x:h) : t
        [] -> [[x]]

loadAsset :: String -> String -> Asset
loadAsset assetName contents =
    let ls = lines contents
        priceRows = mapMaybe parseRow (stripHeaders ls)
    in Asset assetName priceRows

mapMaybe :: (a -> Maybe b) -> [a] -> [b]
mapMaybe _ [] = []
mapMaybe f (x:xs) = case f x of
    Just y -> y : mapMaybe f xs
    Nothing -> mapMaybe f xs