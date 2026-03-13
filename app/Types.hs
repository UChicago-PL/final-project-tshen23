module Types where

import Data.Time ( Day )

data PriceRow = PriceRow
  { date :: Day
  , close :: Double
  } deriving (Show)

data Asset = Asset
  { name :: String
  , rows :: [PriceRow]
  } deriving (Show)

data IndexSpec = ManualIndex
    { indexName :: String
    , weights   :: [(String, Double)]
    }
  | SharpeIndex String Int Int
  deriving (Show)

getIndexName :: IndexSpec -> String
getIndexName (ManualIndex n _) = n
getIndexName (SharpeIndex n _ _) = n

data Metrics = Metrics
  { totalReturn :: Double
  , annualizedReturn :: Double
  , volatility :: Double
  , sharpeRatio :: Double
  } deriving (Show)