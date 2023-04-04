# Binance 24-hour Symbols Stats

This subsystem allows you to fetch 24-hour data from Binance for various trading symbols
using https://api.binance.com/api/v3/ticker/24h rest api method.
It store info into binance.ticker_data table.
Among others it allows to find the most popular symbols based on their USDT volume.

## Files

- `symbol24.sql`: Contains the `binance.ticker_data` table definition and the `binance.update_ticker_data()` function which fetches and inserts the ticker 24-hour data into the `binance.ticker_data` table.
- `usdt_volume.sql`: Contains the `binance.get_usdt_volume()` function which calculates the USDT volume for a given trading symbol and day, and two views `binance.symbol_usdt_volume` and `binance.max_usdt_volume` which provide the USDT volume and the most popular symbols based on their USDT volume, respectively.

## Scheduled update
  It schedules update of daily data on 10 minute basis to have and idea how the volume performs over day for the symbols.

## Usage

1. Execute the `symbol24.sql` file to create the `binance.ticker_data` table and the `binance.update_ticker_data()` function.
2. Execute the `usdt_volume.sql` file to create the `binance.get_usdt_volume()` function and the `binance.symbol_usdt_volume` and `binance.max_usdt_volume` views.
3. Call the `binance.update_ticker_data()` function to fetch and store the 24-hour data for the trading symbols.
4. Query the `binance.symbol_usdt_volume` and `binance.max_usdt_volume` views to find the most popular symbols based on their USDT volume.
