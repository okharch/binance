drop view if exists binance.daily_stats cascade ;
create view binance.daily_stats as
select symbol
     ,count(*)
     ,round((avg(high_price/low_price)-1)*100,4) avg_volatility
     ,round((max(high_price/low_price)-1)*100,4) max_volatility
     ,round(sum(volume*close_price)) total_amount
     ,round(avg(volume*close_price)) avg_per_day
     ,round(max(volume*close_price)) max_per_day
from binance.klines
where period='1d' and open_time>ts2ms(now()-(interval '1 day')*30)
group by 1;


drop view if exists binance.hourly_stats cascade ;
create view binance.hourly_stats as
select symbol
     ,count(*)
     ,round((avg(high_price/low_price)-1)*100,4) avg_volatility
     ,round((max(high_price/low_price)-1)*100,4) max_volatility
     ,round(sum(volume*close_price)) total_amount
     ,round(avg(volume*close_price)) avg_per_day
     ,round(max(volume*close_price)) max_per_day
from binance.klines
where period='1h' and open_time>ts2ms(now()-(interval '1 hour')*24*7)
group by 1;
