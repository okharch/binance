create or replace procedure binance.add_symbol_klines(
    IN asymbol VARCHAR(20),
    IN aperiod VARCHAR(4)
)
    LANGUAGE plpgsql
AS $$
/*
The add_symbol_klines procedure takes two input parameters: asymbol and aperiod, both of type VARCHAR. The purpose of this procedure is to insert a new row into the binance.symbol_klines table with the given asymbol and aperiod values, but only if the aperiod value exists in the kline_periods table.

The binance.symbol_klines table is used to update all required symbols and periods each minute. Therefore, this procedure ensures that only valid aperiod values are inserted into the symbol_klines table. If the aperiod value does not exist in the kline_periods table, it will raise an exception with a message "not valid period" and the value of aperiod, and the insertion will not be performed.

The valid aperiod values for this procedure are those supported by the Binance Kline REST API methods, which include: 1m, 3m, 5m, 15m, 30m, 1h, 2h, 4h, 6h, 8h, 12h, 1d, 3d, 1w, 1M.
*/

BEGIN
    if not exists (select 1 from kline_periods where period=aperiod) then
        raise exception 'not valid period: %', aperiod;
    end if;
    INSERT INTO binance.symbol_klines(symbol, period) VALUES (asymbol,aperiod)
    ON CONFLICT DO NOTHING ;
END
$$;
