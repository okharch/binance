package ticker

import (
	"math"
	"math/rand"
	"testing"
	"time"

	"github.com/okharch/binance/klines"
)

func generateKLines(n int) ([]klines.KLineEntry, []klines.KLineEntry, []klines.KLineEntry, []klines.KLineEntry) {
	// Set up random number generator
	rand.Seed(time.Now().UnixNano())

	// Generate 1m klines for n minutes
	data := []klines.KLineEntry{}
	for i := 0; i < n; i++ {
		kline := klines.KLineEntry{
			OpenTime:   time.Unix(int64(i*60), 0).UnixMilli(),
			CloseTime:  time.Unix(int64((i+1)*60), 0).UnixMilli() - 1,
			OpenPrice:  math.Round(rand.Float64()*10000) / 100,
			ClosePrice: math.Round(rand.Float64()*10000) / 100,
			HighPrice:  math.Round(rand.Float64()*10000) / 100,
			LowPrice:   math.Round(rand.Float64()*10000) / 100,
			Volume:     math.Round(rand.Float64()*100000) / 100,
		}
		data = append(data, kline)
	}

	// Calculate aggregations for specified periods
	getAgg := func(data []klines.KLineEntry, period int) []klines.KLineEntry {
		agg := []klines.KLineEntry{}
		for i := 0; i < n; i += period {
			startIndex := i
			endIndex := min(i+period, n)

			aggEntry := klines.KLineEntry{
				OpenTime:   data[startIndex].OpenTime,
				CloseTime:  data[endIndex-1].CloseTime,
				OpenPrice:  data[startIndex].OpenPrice,
				ClosePrice: data[endIndex-1].ClosePrice,
				HighPrice:  data[startIndex].HighPrice,
				LowPrice:   data[startIndex].LowPrice,
				Volume:     0,
			}

			for j := startIndex; j < endIndex; j++ {
				aggEntry.HighPrice = math.Max(aggEntry.HighPrice, data[j].HighPrice)
				aggEntry.LowPrice = math.Min(aggEntry.LowPrice, data[j].LowPrice)
				aggEntry.Volume += data[j].Volume
			}

			agg = append(agg, aggEntry)
		}
		return agg
	}

	// Generate expected results for 1m, 15m, 30m, and 1h periods
	expected1m := data
	expected15m := getAgg(data, 15)
	expected30m := getAgg(data, 30)
	expected1h := getAgg(data, 60)

	return expected1m, expected15m, expected30m, expected1h
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

const float64EqualityThreshold = 1e-9

func unEqual(a, b float64) bool {
	return math.Abs(a-b) > float64EqualityThreshold
}
func TestGetKLines(t *testing.T) {
	// Generate random klines and expected results
	n := 1440
	expected1m, expected15m, expected30m, expected1h := generateKLines(n)

	// Test GetKLines for 1m, 15m, 30m, and 1h periods from different positions
	testCases := []struct {
		position    int
		period      time.Duration
		expected    []klines.KLineEntry
		description string
	}{
		{n - 1, time.Minute, expected1m, "1m from last position"},
		{n - 1, 15 * time.Minute, expected15m, "15m from last position"},
		{n - 1, 30 * time.Minute, expected30m, "30m from last position"},
		{n - 1, time.Hour, expected1h, "1h from last position"},
		{n - 30, time.Minute, expected1m[:n-29], "1m from position -29"},
		{n - 90, 15 * time.Minute, expected15m[:len(expected15m)-5], "15m from position 90"},
		{n - 180, 30 * time.Minute, expected30m[:len(expected30m)-5], "30m from position 180"},
		{n - 360, time.Hour, expected1h[:len(expected1h)-5], "1h from position 360"},
	}

	for _, tc := range testCases {
		// Initialize ticker with the generated data and current position
		klineData := &klines.KLineData{
			Period: 60 * time.Second,
			Data:   expected1m,
		}
		ticker := &Ticker{
			position:  tc.position,
			klineData: klineData,
		}

		// Test GetKLines for the current period and position
		t.Run(tc.description, func(t *testing.T) {
			klines := make([]klines.KLineEntry, n/int(tc.period/time.Minute))
			klines = ticker.GetKLines(klines, tc.period)
			if len(klines) != len(tc.expected) {
				t.Errorf("Unexpected number of klines returned. Expected %v, got %v", len(tc.expected), len(klines))
			}
			for i := range klines {
				g := klines[i]
				e := tc.expected[i]
				if g.OpenTime != e.OpenTime {
					t.Errorf("Unexpected OpenTime returned at index %v. Expected %v, got %v", i, g.OpenTime, e.OpenTime)
				}
				if g.CloseTime != e.CloseTime {
					t.Errorf("Unexpected %v returned at index %v. Expected %v, got %v", "CloseTime", i, e.CloseTime, g.CloseTime)
				}
				if unEqual(g.LowPrice, e.LowPrice) {
					t.Errorf("Unexpected LowPrice returned at index %v. Expected %v, got %v", i, g.LowPrice, e.LowPrice)
				}
				if unEqual(g.OpenPrice, e.OpenPrice) {
					t.Errorf("Unexpected %v returned at index %v. Expected %v, got %v", "OpenPrice", i, e.OpenPrice, g.OpenPrice)
				}
				if unEqual(g.HighPrice, e.HighPrice) {
					t.Errorf("Unexpected %v returned at index %v. Expected %v, got %v", "HighPrice", i, e.HighPrice, g.HighPrice)
				}
				if unEqual(g.Volume, e.Volume) {
					t.Errorf("Unexpected %v returned at index %v. Expected %v, got %v", "Volume", i, e.Volume, g.Volume)
				}
				if unEqual(g.QuoteAssetVolume, e.QuoteAssetVolume) {
					t.Errorf("Unexpected %v returned at index %v. Expected %v, got %v", "QuoteAssetVolume", i, e.QuoteAssetVolume, g.QuoteAssetVolume)
				}
				if unEqual(g.TakerBuyBaseAssetVolume, e.TakerBuyBaseAssetVolume) {
					t.Errorf("Unexpected %v returned at index %v. Expected %v, got %v", "TakerBuyBaseAssetVolume", i, e.TakerBuyBaseAssetVolume, g.TakerBuyBaseAssetVolume)
				}
				if unEqual(g.TakerBuyQuoteAssetVolume, e.TakerBuyQuoteAssetVolume) {
					t.Errorf("Unexpected %v returned at index %v. Expected %v, got %v", "TakerBuyQuoteAssetVolume", i, e.TakerBuyQuoteAssetVolume, g.TakerBuyQuoteAssetVolume)
				}
			}
		})
	}
}
