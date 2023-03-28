## Binance API Klines Endpoint

The `/api/v3/klines` endpoint of the Binance API returns kline/candlestick bars for a given symbol 
and time interval. Klines are uniquely identified by their open time.

Example request:
````
curl -X 'GET' 'https://api.binance.com/api/v3/klines?symbol=BTCUSDT&interval=1m&limit=100' -H 'accept: application/json'
````

### The response
 
The response is a list of lists, where each inner list contains data for a single kline/candlestick, 
in the following format:

| Column Name                   | Data Type      | Description                                                                                                                                               |
|-------------------------------|----------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| open_time                     | BIGINT         | The timestamp of the start time of the kline/candlestick data point, in milliseconds since the Unix epoch.                                              |
| open_price                    | NUMERIC(18, 8) | The opening price of the trading pair during this interval.                                                                                              |
| high_price                    | NUMERIC(18, 8) | The highest price of the trading pair during this interval.                                                                                              |
| low_price                     | NUMERIC(18, 8) | The lowest price of the trading pair during this interval.                                                                                               |
| close_price                   | NUMERIC(18, 8) | The closing price of the trading pair during this interval.                                                                                              |
| volume                        | NUMERIC(28, 8) | The trading volume during this interval.                                                                                                                 |
| close_time                    | BIGINT         | The timestamp of the end time of the kline/candlestick data point, in milliseconds since the Unix epoch.                                                |
| quote_asset_volume            | NUMERIC(28, 8) | The total value of the trading volume in the quote asset, which is the second asset in the trading pair (in this case, USDT).                          |
| num_trades                    | BIGINT         | The number of trades that occurred during this interval.                                                                                                  |
| taker_buy_base_asset_volume   | NUMERIC(28, 8) | The total amount of the base asset (in this case, BTC) that was bought by taker trades during this interval.                                             |
| taker_buy_quote_asset_volume  | NUMERIC(28, 8) | The total value of the base asset volume in the quote asset (USDT) that was bought by taker trades during this interval.                                |
