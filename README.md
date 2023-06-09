# Database for watching binance symbols performance

## symbol_prices
This is the list of all binance symbols and their latest prices.
This data could be updated by update_prices procedure.

## klines

candle data for symbol and period. 
this data is used by indicators calculation, 
price information, etc. 

## symbol_klines
lists which symbols and periods data for klines should be fetched

## trading indicators
  ### bolliger_band(symbol, period, limit_number)

## signals
  ### sol_bollinger - sends buy/sell signal for solana


## Requirements

- PostgreSQL 10 or higher
- http extension for postgresql: https://github.com/pramsey/pgsql-http#installation
- scheduler extension for postgresql: scheduler extension for postgresql

## Installation

### install and setup cronjob extension
  1. https://github.com/citusdata/pg_cron#installing-pg_cron
  2. pg_hba.conf add / replace line for local access
   host    all         all          127.0.0.1/32           trust
  3. login to database where pg_cron operates and execute:
     ```UPDATE cron.job SET nodename = '';```
     

To install the system, execute the SQL scripts in the following order:

1. `create_tables.sql`: This script creates the necessary tables for the system.
2. `create_functions.sql`: This script creates the stored procedures for the system.
3. `unit_tests.sql`: This script runs the unit tests for the system.

After executing these scripts, the system will be ready to use and collecting data with a minute period.

## Usage

### Creating Alerts

To create an alert, insert a record into the `alerts` table with the following fields:

- `user_id`: The ID of the user who created the alert.
- `symbol`: The symbol to watch for price changes.
- `price`: The price at which to trigger the alert.
- `kind`: The kind of alert to trigger: 0 for when the price goes below the trigger value, and 1 for when the price goes above the trigger value.

### Updating Prices && Retrieving Triggered Alerts

To update the prices and retrieve the alerts, call the `update_prices` function with a JSON array of price updates. 
The JSON array should have the following format:

[
{
"symbol": "BTCUSD",
"price": 23000
},
{
"symbol": "ETHUSD",
"price": 900
}
]


The `symbol` field should match the symbol used in the `alerts` table. 
The `price` field should be the current price for that symbol.

it returns a result set with the following fields:

- `user_id`: The ID of the user who created the alert.
- `symbol`: The symbol that triggered the alert.
- `price`: The current price of the symbol.
- `kind`: The kind of alert that was triggered.

chat bot should send messages about price alerts to specific users for given symbols. 

### Unit Tests

To run the unit tests, execute the `unit_tests.sql` script. 
This script will run several tests to verify that the database is functioning correctly.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
