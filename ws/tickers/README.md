# Binance Ticker Data Importer

This script creates a table and a stored procedure to import and store Binance ticker data. The table `binance.ticker_data` stores the data, while the stored procedure `binance.update_ticker_data()` fetches the data from Binance API and inserts the records in the table.

## Table Schema

The `binance.ticker_data` table has the following columns:

- `day`: Timestamp with timezone, default to current day
- `symbol_id`: Symbol ID (Foreign key referencing `binance.exchange_symbols`)
- `price_change`: Price change
- `price_change_percent`: Price change percent
- `weighted_avg_price`: Weighted average price
- `prev_close_price`: Previous close price
- `last_price`: Last price
- `last_qty`: Last quantity
- `bid_price`: Bid price
- `ask_price`: Ask price
- `open_price`: Open price
- `high_price`: High price
- `low_price`: Low price
- `volume`: Volume
- `quote_volume`: Quote volume
- `open_time`: Open time
- `close_time`: Close time

Primary key: (`symbol_id`, `day`)

## Stored Procedure

The `binance.update_ticker_data()` stored procedure performs the following steps:

1. Check if there is already data for the current day. If yes, raise a warning and exit.
2. Make an API call to fetch ticker data from `https://api.binance.com/api/v3/ticker/24hr`.
3. Check if the API response status is OK (200). If not, raise a warning and exit.
4. Insert ticker data into the `binance.ticker_data` table.

## Usage

To use the script, run the provided SQL commands in your PostgreSQL environment.

Once the table and stored procedure are created, you can call the `binance.update_ticker_data()` procedure to import the data:

```sql
SELECT binance.update_ticker_data();
```
## Volume vs Quote Volume

Volume and Quote Volume are two different measures used in trading to provide information about the trading activity for a particular asset or trading pair.

1. **Volume**: This refers to the total amount of the base asset that has been traded within a specified period of time, usually expressed in the base asset's units. For example, if you are looking at the trading pair BTC/USDT, the volume represents the total number of Bitcoins traded during the time frame, regardless of the price at which they were traded.

2. **Quote Volume**: This represents the total value of the trades executed in the quote currency within a specified period of time. Using the same BTC/USDT trading pair example, the quote volume represents the total amount of USDT involved in all the trades made during the time frame.

In summary, Volume measures the trading activity in terms of the base asset, while Quote Volume measures the trading activity in terms of the quote currency. These two metrics provide insights into the liquidity and popularity of a trading pair, as well as the overall market interest in the asset.
