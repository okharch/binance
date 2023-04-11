package ticker

import (
	"context"
	"github.com/jmoiron/sqlx"
	"github.com/okharch/binance/indicators"
	"github.com/okharch/binance/indicators/mac"
	"github.com/okharch/binance/klines"
	"log"
	"runtime"
	"sync"
)

type TGenIndicatorSignal struct {
	IndicatorType indicators.IndicatorType
	IndicatorFunc func(kLines []klines.KLineEntry, params []int) indicators.TradeSignal
	PeriodIndex, PeriodMinutes,
	MinLongTerm, MaxLongTerm int
	ShortTermMul, ShortTermDiv int
}

func getIndicatorsList() []TGenIndicatorSignal {
	return macIndicatorsList()
}

const MaxLongTerm = 100

func macIndicatorsList() (result []TGenIndicatorSignal) {
	for i, pm := range PeriodMinutes {
		result = append(result, TGenIndicatorSignal{
			indicators.IndicatorTypeMAC, mac.MAC,
			i, pm, 10, MaxLongTerm,
			2, 3,
		})
	}
	return
}

func insertIndicatorSignals(db *sqlx.DB, signals []indicators.IndicatorSignal) error {
	query := `
        INSERT INTO binance.indicator_signal (open_time, symbol_id, indicator_id, period, volume)
        VALUES (:open_time, :symbol_id, :indicator_id, :period, :volume)
    `
	_, err := db.NamedExec(query, signals)
	return err
}

// GenerateSignals generates indicator signals for a given symbol using the provided
// TGenIndicatorSignals, and inserts them into a database using a given context and SQLx database pointer.
func (t *Ticker) GenerateSignals(ctx context.Context, db *sqlx.DB, symbolId int32) error {
	var signals []indicators.IndicatorSignal
	insertSignals := func() error {
		if len(signals) == 0 {
			return nil
		}
		err := insertIndicatorSignals(db, signals)
		if err != nil {
			return err
		}
		signals = signals[:0] // reset slice
		return nil
	}
	// this server handles concurrent access to signals slice using signalChannel
	var waitSignals sync.WaitGroup
	signalChannel := make(chan indicators.IndicatorSignal, 1024)
	waitSignals.Add(1)
	go func() {
		defer waitSignals.Done()
		for signal := range signalChannel {
			signals = append(signals, signal)
		}
	}()

	concurrentRoutines := make(chan struct{}, runtime.NumCPU())
	var wg sync.WaitGroup
	generateSignals := func(indSignal TGenIndicatorSignal) {
		defer wg.Done()
		// check if input ranges valid
		if int(indSignal.IndicatorType) > 1024 {
			log.Fatalf("invalid indicator type exceeds 1024: %s", indSignal.IndicatorType)
		}
		if indSignal.MaxLongTerm >= 1<<11 {
			log.Fatalf("invalid longTerm value: %d exceeds 2048", indSignal.MaxLongTerm)
		}
		if indSignal.ShortTermDiv != 0 {
			maxShortTerm := indSignal.MaxLongTerm * indSignal.ShortTermMul / indSignal.ShortTermDiv
			if maxShortTerm >= 1<<10 {
				log.Fatalf("invalid shortTerm value: %d exceeds 1024", maxShortTerm)
			}
		}
		// wait free slot for execution or cancelling event
		select {
		case <-ctx.Done():
			return
		case concurrentRoutines <- struct{}{}: // take a slot
		}
		defer func() {
			<-concurrentRoutines // release the slot
		}()
		// calculate shortTerm range before loop
		var minShortTerm, maxShortTerm int
		if indSignal.ShortTermDiv != 0 {
			minShortTerm = indSignal.MinLongTerm * indSignal.ShortTermMul / indSignal.ShortTermDiv
			maxShortTerm = indSignal.MaxLongTerm * indSignal.ShortTermMul / indSignal.ShortTermDiv
		}
		for longTerm := indSignal.MinLongTerm; longTerm <= indSignal.MaxLongTerm; longTerm++ {
			// check min..max < longTerm
			// we need one more element to calculate two following moving average: 0..n and 1..n+1
			longTermKLines := t.GetKLines(indSignal.PeriodIndex, indSignal.PeriodMinutes, longTerm+1)
			if longTermKLines == nil {
				continue
			}
			kl := &longTermKLines[longTerm]
			openTime := kl.OpenTime
			volume := kl.Volume
			volAvg := klines.VolumeAvg(longTermKLines[1:])
			vol3Avg := klines.VolumeAvg(longTermKLines[longTerm-3+1 : longTerm+1])
			for shortTerm := minShortTerm; shortTerm <= maxShortTerm; shortTerm++ {
				signal := indSignal.IndicatorFunc(longTermKLines, []int{longTerm, shortTerm})
				if signal != indicators.TradeNone {
					indicatorId := int32((int(indSignal.IndicatorType)<<10+longTerm)<<12 + shortTerm)
					if signal == indicators.TradeSell {
						indicatorId = -indicatorId
					}
					signalChannel <- indicators.IndicatorSignal{
						OpenTime:    openTime,
						SymbolId:    symbolId,
						IndicatorId: indicatorId,
						Period:      int8(indSignal.PeriodIndex),
						Volume:      volume,
						VolAvg:      volAvg,
						Vol3Avg:     vol3Avg,
					}
				}
			}
		}
	}
	for _, indicator := range getIndicatorsList() {
		wg.Add(1)
		go generateSignals(indicator)
	}
	wg.Wait()
	close(signalChannel)
	waitSignals.Wait()
	if err := ctx.Err(); err != nil {
		return err
	}
	return insertSignals()
}

func GetMaxMinutes() int {
	return MaxLongTerm * PeriodMinutes[len(PeriodMinutes)-1]
}
