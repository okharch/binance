package ticker

import (
	"context"
	"github.com/jmoiron/sqlx"
	"github.com/okharch/binance/indicators"
	"github.com/okharch/binance/klines"
	"log"
	"runtime"
	"sync"
)

type TGenIndicatorSignal struct {
	IndicatorType                                        indicators.IndicatorType
	IndicatorFunc                                        func(kLines []klines.KLineEntry, params []int) TradeSignal
	PeriodIndex, PeriodMinutes, MinLongTerm, MaxLongTerm int
	ShortTermMul, ShortTermDiv                           int
}

func InsertIndicatorSignals(db *sqlx.DB, signals []indicators.IndicatorSignal) error {
	query := `
        INSERT INTO binance.indicator_signal (open_time, symbol_id, indicator_id, period, volume)
        VALUES (:open_time, :symbol_id, :indicator_id, :period, :volume)
    `
	_, err := db.NamedExec(query, signals)
	return err
}

func (t *Ticker) GenerateSignals(ctx context.Context, db *sqlx.DB, symbolId int32, openTime int64, volume float64, indicatorSignals []TGenIndicatorSignal, max_procs int) error {
	var signals []indicators.IndicatorSignal

	signalChannel := make(chan indicators.IndicatorSignal, 1024)

	insertSignals := func() error {
		if len(signals) == 0 {
			return nil
		}
		err := InsertIndicatorSignals(db, signals)
		if err != nil {
			return err
		}
		signals = signals[:0] // reset slice
		return nil
	}
	var waitSignals sync.WaitGroup
	go func() {
		waitSignals.Add(1)
		defer waitSignals.Done()
		for signal := range signalChannel {
			signals = append(signals, signal)
			if len(signals) == 1024 {
				err := insertSignals()
				if err != nil {
					log.Printf("Failed to insert signals: %v", err)
				}
			}
		}
	}()

	concurrentRoutines := make(chan struct{}, runtime.NumCPU())

	var wg sync.WaitGroup
	checkSignal := func(indSignal TGenIndicatorSignal, longTerm, shortTerm int, longTermKLines []klines.KLineEntry) {
		wg.Add(1)
		defer wg.Done()
		select {
		case <-ctx.Done():
			return
		case concurrentRoutines <- struct{}{}: // take a slot
			signal := indSignal.IndicatorFunc(longTermKLines, []int{longTerm, shortTerm})
			if signal != TradeNone {
				indicatorId := (int32(indicators.IndicatorTypeMAC)<<10+int32(longTerm))<<10 + int32(shortTerm)
				if signal == TradeSell {
					indicatorId = -indicatorId
				}
				signalChannel <- indicators.IndicatorSignal{
					OpenTime:    openTime,
					SymbolId:    symbolId,
					IndicatorId: indicatorId,
					Period:      int8(indSignal.PeriodIndex),
					Volume:      volume,
				}

			}
			<-concurrentRoutines // release the slot
		}
	}
	for _, indSignal := range indicatorSignals {
		var minShortTerm, maxShortTerm int
		if indSignal.ShortTermDiv != 0 {
			minShortTerm = indSignal.MinLongTerm * indSignal.ShortTermMul / indSignal.ShortTermDiv
			maxShortTerm = indSignal.MaxLongTerm * indSignal.ShortTermMul / indSignal.ShortTermDiv
		}
		for longTerm := indSignal.MinLongTerm; longTerm <= indSignal.MaxLongTerm; longTerm++ {
			// check min..max < longTerm
			longTermKLines := t.GetKLines(indSignal.PeriodIndex, indSignal.PeriodMinutes, longTerm+2)
			for shortTerm := minShortTerm; shortTerm <= maxShortTerm; shortTerm++ {
				go checkSignal(indSignal, longTerm, shortTerm, longTermKLines)
			}
		}
	}
	wg.Wait()
	close(signalChannel)
	if err := ctx.Err(); err != nil {
		return err
	}
	waitSignals.Wait()
	return insertSignals()
}
