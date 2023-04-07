package ticker

import (
	"context"
	"github.com/okharch/binance/klines"
	"math"
	"time"
)

type Ticker struct {
	position int
	data1m   []klines.KLineEntry                   // 1 minute data for ticker
	pdata    map[time.Duration][]klines.KLineEntry // other periods klines
}

func (t *Ticker) allocatePeriod(period time.Duration) {
	// calculate the maximum number of klines to store for this period
	count1mPeriods := int(period / time.Minute)
	klinesLen := (len(t.data1m) + count1mPeriods - 1) / count1mPeriods
	// add the new slice to the pdata map
	t.pdata[period] = make([]klines.KLineEntry, klinesLen)
}

func NewTicker(data1m []klines.KLineEntry, periods []time.Duration) *Ticker {
	t := &Ticker{
		data1m: data1m,
		pdata:  make(map[time.Duration][]klines.KLineEntry),
	}

	// allocate kline slices for each period in the periods slice
	for _, period := range periods {
		t.allocatePeriod(period)
	}

	return t
}

// Get a channel of klines starting from the beginning
func (t *Ticker) GetTicksChannel(ctx context.Context) <-chan klines.KLineEntry {
	channel := make(chan klines.KLineEntry)

	// Start a goroutine to send klines to the channel
	go func() {
		defer close(channel)

		for i, kline := range t.data1m {
			select {
			case <-ctx.Done():
				return
			case channel <- kline:
				t.updatePosition(i)
			}
		}
	}()

	return channel
}

// is used internally when iterating over 1m candles to update/append new candles for larger periods
func (t *Ticker) updatePosition(new1mposition int) {
	// update the current position to the new 1 minute position
	t.position = new1mposition

	// get the new 1 minute kline
	kLine1m := t.data1m[new1mposition]

	// iterate over each period in the pdata map
	for period, kLines := range t.pdata {
		// calculate the number of 1 minute candles in the current period
		count1mPeriods := int(period / time.Minute)

		// calculate the index of the current kLine for the current period
		idx := new1mposition / count1mPeriods

		// get the current kLine for the current period
		kLine := &kLines[idx]

		// check if we just started a new period
		if t.position%count1mPeriods == 0 {
			// initialize the open price and time and other aggregate values for the new period
			kLine.OpenPrice = kLine1m.OpenPrice
			kLine.OpenTime = kLine1m.OpenTime
			kLine.HighPrice = kLine1m.HighPrice
			kLine.LowPrice = kLine1m.LowPrice
			kLine.Volume = kLine1m.Volume
			kLine.QuoteAssetVolume = kLine1m.QuoteAssetVolume
			kLine.NumTrades = kLine1m.NumTrades
			kLine.TakerBuyBaseAssetVolume = kLine1m.TakerBuyBaseAssetVolume
			kLine.TakerBuyQuoteAssetVolume = kLine1m.TakerBuyQuoteAssetVolume
		} else {
			// aggregate the kLine data if we're not at the start of a new period
			kLine.HighPrice = math.Max(kLine.HighPrice, kLine1m.HighPrice)
			kLine.LowPrice = math.Min(kLine.LowPrice, kLine1m.LowPrice)
			kLine.Volume += kLine1m.Volume
			kLine.QuoteAssetVolume += kLine1m.QuoteAssetVolume
			kLine.NumTrades += kLine1m.NumTrades
			kLine.TakerBuyBaseAssetVolume += kLine1m.TakerBuyBaseAssetVolume
			kLine.TakerBuyQuoteAssetVolume += kLine1m.TakerBuyQuoteAssetVolume
		}

		// update the close price and time for the kLine
		kLine.ClosePrice = kLine1m.ClosePrice
		kLine.CloseTime = kLine1m.CloseTime
	}
}

// Get specified number of candlesticks before and including current position
func (t *Ticker) GetKLines(period time.Duration, n int) []klines.KLineEntry {
	count1mPeriods := int(period / time.Minute)

	// calculate the index of the current kLine for the current period
	idx := t.position / count1mPeriods
	return t.pdata[period][idx-n+1 : idx+1]
}

// Utility function to return the maximum of two integers
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
