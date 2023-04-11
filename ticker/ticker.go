package ticker

import (
	"context"
	"github.com/okharch/binance/klines"
	"math"
)

var PeriodMinutes = []int{1, 5, 10, 15, 30, 60, 240, 720, 1440, 1440 * 3, 1440 * 7}

type Ticker struct {
	position int
	periods  [][]klines.KLineEntry
}

func (t *Ticker) allocatePeriods() {
}

func NewTicker(data1m []klines.KLineEntry) *Ticker {
	t := &Ticker{}
	// calculate the maximum number of klines to store for this period
	t.periods = make([][]klines.KLineEntry, len(PeriodMinutes))
	t.periods[0] = data1m
	minutes := len(data1m)
	for i, m := range PeriodMinutes[1:] {
		t.periods[i+1] = make([]klines.KLineEntry, (minutes+m-1)/m)
	}

	return t
}

// Get a channel of klines starting from the beginning
func (t *Ticker) GetTicksChannel(ctx context.Context) <-chan klines.KLineEntry {
	channel := make(chan klines.KLineEntry)

	// Start a goroutine to send klines to the channel
	go func() {
		defer close(channel)
		// loop over minute bars
		for i, kline := range t.periods[0] {
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
	kLines1m := t.periods[0]
	kLine1m := &kLines1m[new1mposition]

	// iterate over each period in the pdata map
	for i, count1mPeriods := range PeriodMinutes[1:] {
		// calculate the index of the current kLine for the current period
		idx := new1mposition / count1mPeriods

		// get the current kLine for the current period
		kLines := t.periods[i+1]
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
func (t *Ticker) GetKLines(periodIndex, count1mPeriods, n int) []klines.KLineEntry {
	// calculate the index of the current kLine for the current period
	idx := t.position / count1mPeriods
	if idx <= n {
		return nil
	}
	return t.periods[periodIndex][idx-n+1 : idx+1]
}

// Utility function to return the maximum of two integers
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
