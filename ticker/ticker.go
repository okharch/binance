package ticker

import (
	"context"
	"github.com/okharch/binance/klines"
	"math"
	"time"
)

type Ticker struct {
	position  int
	klineData *klines.KLineData
}

// Get a channel of klines starting from the beginning
func (t *Ticker) GetTicksChannel(ctx context.Context) <-chan klines.KLineEntry {
	channel := make(chan klines.KLineEntry)

	// Start a goroutine to send klines to the channel
	go func() {
		defer close(channel)

		for _, kline := range t.klineData.Data {
			select {
			case <-ctx.Done():
				return
			case channel <- kline:
				t.position++
			}
		}
	}()

	return channel
}

// Get candlestick data for a given period
func (t *Ticker) GetKLines(aKlines []klines.KLineEntry, period time.Duration) []klines.KLineEntry {
	// Calculate the number of periods to aggregate
	ticksPerPeriod := int(period / t.klineData.Period)
	requiredTicks := cap(aKlines)
	underlyingTicks := ticksPerPeriod * requiredTicks

	// Calculate the starting position for the requested period
	startPosition := max(t.position-underlyingTicks+1, 0)
	providedTicks := (t.position - startPosition + 1) / ticksPerPeriod
	aKlines = aKlines[0:providedTicks]
	// Aggregate kline data for the given period
	var rTick *klines.KLineEntry
	for j, i := 0, startPosition; i <= t.position; i++ {
		tick := &t.klineData.Data[i]
		if i == j*ticksPerPeriod {
			rTick = &aKlines[j]
			j++
			// First kline in the period
			rTick.OpenTime = tick.OpenTime
			rTick.CloseTime = tick.CloseTime
			rTick.OpenPrice = tick.OpenPrice
			rTick.HighPrice = tick.HighPrice
			rTick.LowPrice = tick.LowPrice
			rTick.ClosePrice = tick.ClosePrice
			rTick.Volume = tick.Volume
		} else {
			// Update current kline data
			rTick.HighPrice = math.Max(rTick.HighPrice, tick.HighPrice)
			rTick.LowPrice = math.Min(rTick.LowPrice, tick.LowPrice)
			rTick.ClosePrice = tick.ClosePrice
			rTick.CloseTime = tick.CloseTime
			rTick.Volume += tick.Volume
		}
	}
	return aKlines
}

// Utility function to return the maximum of two integers
func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
