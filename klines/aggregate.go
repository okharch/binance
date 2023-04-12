package klines

import (
	"math"
)

type PeriodAggregate struct {
	OpenPrice     []float64
	LowPrice      []float64
	HighPrice     []float64
	ClosePrice    []float64
	Volume        []float64
	QuoteAssetVol []float64
	NumTrades     []int64
	TakerBuyBase  []float64
	TakerBuyQuote []float64
}

func AggregatePeriod(klines1m []KLineEntry, numberOfMinutes int) PeriodAggregate {
	// Calculate the number of periods in the klines1m
	numPeriods := (len(klines1m) + numberOfMinutes - 1) / numberOfMinutes

	// Initialize the period aggregate struct
	periodAgg := PeriodAggregate{
		OpenPrice:     make([]float64, numPeriods),
		LowPrice:      make([]float64, numPeriods),
		HighPrice:     make([]float64, numPeriods),
		ClosePrice:    make([]float64, numPeriods),
		Volume:        make([]float64, numPeriods),
		QuoteAssetVol: make([]float64, numPeriods),
		NumTrades:     make([]int64, numPeriods),
		TakerBuyBase:  make([]float64, numPeriods),
		TakerBuyQuote: make([]float64, numPeriods),
	}

	// Loop through the klines1m and aggregate the data into the periods
	period := int64(numberOfMinutes * 60000)
	i := 0
	l := len(klines1m)
	for p := 0; p < numPeriods; p++ {
		k := &klines1m[i]
		periodAgg.OpenPrice[p] = k.OpenPrice
		startTime := k.OpenTime
		endTime := startTime + period - 1
		highPrice := k.HighPrice
		lowPrice := k.LowPrice
		volume := k.Volume
		quoteAssetVol := k.QuoteAssetVolume
		numTrades := k.NumTrades
		takerBuyBase := k.TakerBuyBaseAssetVolume
		takerBuyQuote := k.TakerBuyQuoteAssetVolume
		i++
		for ; i < l; i++ {
			k = &klines1m[i]
			if k.OpenTime > endTime {
				break
			}

			// update aggregates for current period
			highPrice = math.Max(highPrice, k.HighPrice)
			lowPrice = math.Min(lowPrice, k.LowPrice)
			volume += k.Volume
			quoteAssetVol += k.QuoteAssetVolume
			numTrades += k.NumTrades
			takerBuyBase += k.TakerBuyBaseAssetVolume
			takerBuyQuote += k.TakerBuyQuoteAssetVolume
		}

		// update the period aggregate with the aggregated values
		periodAgg.LowPrice[p] = lowPrice
		periodAgg.HighPrice[p] = highPrice
		periodAgg.ClosePrice[p] = klines1m[i-1].ClosePrice
		periodAgg.Volume[p] = volume
		periodAgg.QuoteAssetVol[p] = quoteAssetVol
		periodAgg.NumTrades[p] = numTrades
		periodAgg.TakerBuyBase[p] = takerBuyBase
		periodAgg.TakerBuyQuote[p] = takerBuyQuote
	}
	return periodAgg
}
