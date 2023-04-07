package ticker

import (
	"context"
	"github.com/okharch/binance/klines"
	"math"
	"testing"
	"time"
)

func initTestData(n int) (*Ticker, []klines.KLineEntry, []klines.KLineEntry) {
	// create a test data slice with n 1 minute klines
	data1m := make([]klines.KLineEntry, n)
	for i := 0; i < n; i++ {
		data1m[i] = klines.KLineEntry{
			OpenTime:                 time.Now().Add(time.Duration(i) * time.Minute).Unix(),
			CloseTime:                time.Now().Add(time.Duration(i+1) * time.Minute).Unix(),
			OpenPrice:                float64(i),
			LowPrice:                 float64(i),
			HighPrice:                float64(i + 1),
			ClosePrice:               float64(i + 1),
			Volume:                   float64(i),
			QuoteAssetVolume:         float64(i),
			NumTrades:                int64(i),
			TakerBuyBaseAssetVolume:  float64(i),
			TakerBuyQuoteAssetVolume: float64(i),
		}
	}

	// create a new ticker with periods of 15 minutes and 1 hour
	ticker := NewTicker(data1m, []time.Duration{time.Minute * 15, time.Hour})

	// calculate the expected number of klines for the 15 minute and 1 hour periods
	num15m := (n + 15 - 1) / 15
	num1h := (n + 60 - 1) / 60

	// create the expected klines for the 15 minute period
	expected15m := make([]klines.KLineEntry, num15m)
	for i := 0; i < num15m; i++ {
		i0 := i * 15
		i1 := min((i+1)*15-1, n-1)
		v := float64(sum(i0, i1))
		expected15m[i] = klines.KLineEntry{
			OpenTime:                 data1m[i0].OpenTime,
			CloseTime:                data1m[i1].CloseTime,
			OpenPrice:                float64(i0),
			LowPrice:                 float64(i0),
			HighPrice:                float64(i1 + 1),
			ClosePrice:               float64(i1 + 1),
			Volume:                   v,
			QuoteAssetVolume:         v,
			NumTrades:                int64(v),
			TakerBuyBaseAssetVolume:  v,
			TakerBuyQuoteAssetVolume: v,
		}
	}

	// create the expected klines for the 1 hour period
	// create the expected klines for the 1 hour period
	expected1h := make([]klines.KLineEntry, num1h)
	for i := 0; i < num1h; i++ {
		i0 := i * 60
		i1 := min((i+1)*60-1, n-1)
		v := float64(sum(i0, i1))
		expected1h[i] = klines.KLineEntry{
			OpenTime:                 data1m[i0].OpenTime,
			CloseTime:                data1m[i1].CloseTime,
			OpenPrice:                float64(i0),
			ClosePrice:               float64(i1 + 1),
			HighPrice:                float64(i1 + 1),
			LowPrice:                 float64(i0),
			Volume:                   v,
			QuoteAssetVolume:         v,
			NumTrades:                int64(v),
			TakerBuyBaseAssetVolume:  v,
			TakerBuyQuoteAssetVolume: v,
		}
	}

	return ticker, expected15m, expected1h
}

func iterateTickerChannel(ticker *Ticker, ctx context.Context) (got15m, got1h []klines.KLineEntry) {
	ch := ticker.GetTicksChannel(ctx)
	for range ch {

	}
	got15m = ticker.GetKLines(time.Minute*15, (len(ticker.data1m)+15-1)/15)
	got1h = ticker.GetKLines(time.Hour, (len(ticker.data1m)+60-1)/60)
	return
}

func TestGetTicksChannel(t *testing.T) {
	// create a test context with a timeout of 5 seconds
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// initialize test data and ticker
	ticker, expected15m, expected1h := initTestData(100)

	// iterate over ticker channel to get actual kline data
	got15m, got1h := iterateTickerChannel(ticker, ctx)

	// compare expected and actual kline data
	CompareKlines(t, "15m", expected15m, got15m)
	CompareKlines(t, "15m", expected1h, got1h)
}

func CompareKlines(t *testing.T, periodStr string, expected, actual []klines.KLineEntry) {
	// compare lengths of expected and actual slices
	if len(expected) != len(actual) {
		t.Errorf("Expected klines slice length %d, but got %d", len(expected), len(actual))
		return
	}

	// compare each kline entry in the slices
	for i, exp := range expected {
		act := actual[i]
		if exp.OpenTime != act.OpenTime ||
			exp.CloseTime != act.CloseTime ||
			math.Abs(exp.OpenPrice-act.OpenPrice) > 0.01 ||
			math.Abs(exp.ClosePrice-act.ClosePrice) > 0.01 ||
			math.Abs(exp.HighPrice-act.HighPrice) > 0.01 ||
			math.Abs(exp.LowPrice-act.LowPrice) > 0.01 ||
			math.Abs(exp.Volume-act.Volume) > 0.01 ||
			math.Abs(exp.QuoteAssetVolume-act.QuoteAssetVolume) > 0.01 ||
			exp.NumTrades != act.NumTrades ||
			math.Abs(exp.TakerBuyBaseAssetVolume-act.TakerBuyBaseAssetVolume) > 0.01 ||
			math.Abs(exp.TakerBuyQuoteAssetVolume-act.TakerBuyQuoteAssetVolume) > 0.01 {
			t.Errorf("Expected kline[%d] %s %v, but got %v", i, periodStr, exp, act)
		}
	}
}

func TestNewTicker(t *testing.T) {
	// create a test data slice with 100 1 minute klines
	data1m := make([]klines.KLineEntry, 100)
	for i := 0; i < 100; i++ {
		data1m[i] = klines.KLineEntry{
			OpenTime:                 time.Now().Add(time.Duration(i) * time.Minute).Unix(),
			CloseTime:                time.Now().Add(time.Duration(i+1) * time.Minute).Unix(),
			OpenPrice:                float64(i),
			ClosePrice:               float64(i + 1),
			HighPrice:                float64(i + 1),
			LowPrice:                 float64(i),
			Volume:                   float64(i),
			QuoteAssetVolume:         float64(i),
			NumTrades:                int64(i),
			TakerBuyBaseAssetVolume:  float64(i),
			TakerBuyQuoteAssetVolume: float64(i),
		}
	}

	// create a new ticker with periods of 15 minutes and 1 hour
	ticker := NewTicker(data1m, []time.Duration{time.Minute * 15, time.Hour})

	// test that the data1m slice was correctly initialized
	if len(ticker.data1m) != 100 {
		t.Errorf("data1m slice size does not match expected size")
	}

	// test that the pdata map was correctly initialized with the specified periods
	if len(ticker.pdata) != 2 {
		t.Errorf("pdata map size does not match expected size")
	}
	if _, ok := ticker.pdata[time.Minute*15]; !ok {
		t.Errorf("pdata map does not contain 15 minute period")
	}
	if _, ok := ticker.pdata[time.Hour]; !ok {
		t.Errorf("pdata map does not contain 1 hour period")
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func sum(i0, i1 int) int {
	result := 0
	for i := i0; i <= i1; i++ {
		result += i
	}
	return result
}
