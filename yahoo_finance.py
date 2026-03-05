### NOTE: THIS IS ONLY FOR DOWNLOADING ASSET CSVS, ALL ANAYLSIS WILL BE IN HASKELL ###
### Imagine this as me manually downloading the csvs and putting it in a folder ###

import yfinance as yf
import os
import shutil

FOLDER = "assets"

# add any assets as needed
tickers = {
    "sp500": "^GSPC",
    "gold": "GC=F",
    "bonds": "AGG",
    "nasdaq": "^IXIC",
    "vix": "^VIX",
}

if os.path.exists(FOLDER):
    shutil.rmtree(FOLDER)
os.makedirs(FOLDER)

for name, ticker in tickers.items():
    yf.download(ticker, start="2014-01-01", end="2024-01-01").to_csv(f"{FOLDER}/{name}.csv")