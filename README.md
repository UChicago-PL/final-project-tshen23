# Final Project: Haskell Index Backtester

A Haskell tool for constructing and backtesting custom weighted asset indices over historical price data.

To use, edit `indexes.txt`. Each line defines one index:
```
my_index, sp500 0.5, gold 0.5
conservative, bonds 0.7, sp500 0.3
everything, sp500 0.2, gold 0.2, bonds 0.2, nasdaq 0.2, vix 0.2
```

Please Note:
- Asset names must match the CSV filenames in `assets/` (without `.csv`)
- Weights should sum to 1.0

To run:
```bash
cabal run
```

Results are written to `results.csv`.

Progress reports are in `\reports`.

If you want to add more assets, feel free to mess around with and run yahoo_finance.py. Make sure you have yahoo finance installed:
```bash
pip install yfinance
```