package klines

import (
	"github.com/stretchr/testify/assert"
	"testing"
)

func TestAggregatePeriod(t *testing.T) {
	klines1m := make([]KLineEntry, 100)
	for i := 1; i <= 100; i++ {
		klines1m[i-1] = KLineEntry{
			OpenTime:                 int64(i) * 60 * 1000,
			OpenPrice:                float64(i),
			LowPrice:                 float64(i) - 0.5,
			HighPrice:                float64(i) + 1,
			ClosePrice:               float64(i) + 0.5,
			Volume:                   float64(i) * 10,
			CloseTime:                int64(i)*60*1000 - 1,
			QuoteAssetVolume:         float64(i) * 100,
			NumTrades:                int64(i) * 2,
			TakerBuyBaseAssetVolume:  float64(i) * 5,
			TakerBuyQuoteAssetVolume: float64(i) * 50,
		}
	}

	agg := AggregatePeriod(klines1m, 5)

	// Check that the length of each slice in the period aggregate is correct
	assert.Equal(t, len(agg.OpenPrice), 20)
	assert.Equal(t, len(agg.LowPrice), 20)
	assert.Equal(t, len(agg.HighPrice), 20)
	assert.Equal(t, len(agg.ClosePrice), 20)
	assert.Equal(t, len(agg.Volume), 20)
	assert.Equal(t, len(agg.QuoteAssetVol), 20)
	assert.Equal(t, len(agg.NumTrades), 20)
	assert.Equal(t, len(agg.TakerBuyBase), 20)
	assert.Equal(t, len(agg.TakerBuyQuote), 20)

	// Check the values of the period aggregate
	for i := 0; i < 20; i++ {
		expectedOpen := float64(i*5) + 1
		expectedLow := expectedOpen - 0.5
		expectedClose := expectedOpen + 4.5
		expectedHigh := expectedClose + 0.5
		s := float64(sumProgress(i*5+1, 5))
		expectedVolume := s * 10
		expectedQuote := s * 100
		expectedTrades := int64(s) * 2
		expectedTakerBase := s * 5
		expectedTakerQuote := s * 50

		assert.Equal(t, expectedOpen, agg.OpenPrice[i])
		assert.Equal(t, expectedClose, agg.ClosePrice[i])
		assert.Equal(t, expectedLow, agg.LowPrice[i])
		assert.Equal(t, expectedHigh, agg.HighPrice[i])
		assert.Equal(t, expectedVolume, agg.Volume[i])
		assert.Equal(t, expectedQuote, agg.QuoteAssetVol[i])
		assert.Equal(t, expectedTrades, agg.NumTrades[i])
		assert.Equal(t, expectedTakerBase, agg.TakerBuyBase[i])
		assert.Equal(t, expectedTakerQuote, agg.TakerBuyQuote[i])
	}
}

func sumProgress(i, n int) int {
	r := i
	for ; n > 1; n-- {
		i++
		r += i
	}
	return r
}
