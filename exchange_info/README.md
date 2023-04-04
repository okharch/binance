# Binance Exchange Symbols Importer

This script creates a table and a stored procedure to import and store Binance exchange symbols data. The table `binance.exchange_symbols` stores the data, while the stored procedure `binance.import_exchange_symbols()` fetches the data from Binance API and inserts or updates the records in the table.

## Table Schema

The `binance.exchange_symbols` table has the following columns:

- `symbol_id`: Serial primary key
- `symbol`: Symbol name (unique)
- `status`: Symbol status
- `base_asset`: Base asset
- `base_asset_precision`: Base asset precision
- `quote_asset`: Quote asset
- `quote_precision`: Quote precision
- `quote_asset_precision`: Quote asset precision
- `base_commission_precision`: Base commission precision
- `quote_commission_precision`: Quote commission precision
- `default_self_trade_prevention_mode`: Default self-trade prevention mode

## SP binance.import_exchange_symbols()

The `binance.import_exchange_symbols()` stored procedure performs the following steps:

1. Make an API call to fetch exchange info from `https://api.binance.com/api/v3/exchangeInfo`.
2. Check if the API response status is OK (200). If not, raise a warning and exit.
3. Insert or update symbols and their details into the `binance.exchange_symbols` table.

## Usage

To use the script, run the provided SQL commands in your PostgreSQL environment.

Once the table and stored procedure are created, you can call the `binance.import_exchange_symbols()` procedure to import or update the data:

```sql
CALL binance.import_exchange_symbols();
