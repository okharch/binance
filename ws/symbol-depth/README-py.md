# Symbol-Depth.py

This is a Python script that uses web sockets to continually update the bid and ask book changes at Binance, a popular cryptocurrency exchange. The script connects to the Binance WebSocket API and subscribes to the order book for a given trading pair, which is specified as an argument when running the script. 

## Requirements

- Python 3.x
- psycopg2
- websocket-client

## Usage

To run the script, open a command prompt or terminal and navigate to the directory where the script is located. 
Then, run the following command:

```
python symbol-depth.py [symbol]
```

Where `[symbol]` is the trading pair you want to monitor. 
If no symbol is provided, `btcusdt` is used as the default.

## Functionality

The script connects to the Binance WebSocket API and subscribes to the order book for the specified trading pair. 
Whenever a change occurs in the order book 
(i.e., a new order is placed or an existing order is modified or cancelled), 
the script receives a message from the API. 
The `on_message` function is called to process the message, 
which includes updating the bid and ask book changes in a PostgreSQL database.

The database connection details are provided via environment variables, 
specifically `TBOTS_DB` which contains the database connection string. 
Once connected to the database, the script calls a stored procedure `binance.process_depth_update` 
which takes the received message as an argument and processes it to determine 
the symbol, event time, and number of affected asks and bids.

If the stored procedure returns a result, the script prints out the 
symbol, event time, and number of affected asks and bids to the console. 
The database connection is then committed to ensure the changes are saved.

## Conclusion

This script is useful for those who want to monitor bid and ask book changes in real-time on Binance. 
It can be easily customized to include additional functionality such as sending notifications or executing trades based on certain conditions.
