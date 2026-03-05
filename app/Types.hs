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

data IndexSpec = IndexSpec
  { indexName :: String
  , weights :: [(String, Double)]
  } deriving (Show)

data Metrics = Metrics
  { totalReturn :: Double
  , annualizedReturn :: Double
  , volatility :: Double
  , sharpeRatio :: Double
  } deriving (Show)