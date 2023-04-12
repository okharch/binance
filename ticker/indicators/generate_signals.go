package indicators

import (
	"context"
	"github.com/jmoiron/sqlx"
	"github.com/okharch/binance/indicators/mac"
	"github.com/okharch/binance/klines"
	"github.com/okharch/binance/ticker"
	"log"
	"runtime"
	"sync"
)

type TGenIndicatorSignal struct {
	IndicatorType IndicatorType
	IndicatorFunc func(kLines []klines.KLineEntry, params []int) TradeSignal
	PeriodIndex, PeriodMinutes,
	MinLongTerm, MaxLongTerm int
	ShortTermMulMin, ShortTermMulMax, ShortTermDiv int
}

func getIndicatorsList() []TGenIndicatorSignal {
	return macIndicatorsList()
}

const MaxLongTerm = 100

func macIndicatorsList() (result []TGenIndicatorSignal) {
	for i, pm := range ticker.PeriodMinutes {
		result = append(result, TGenIndicatorSignal{
			IndicatorTypeMAC, mac.MAC,
			i, pm, 10, MaxLongTerm,
			3, 7, 10,
		})
	}
	return
}

func insertIndicatorSignals(db *sqlx.DB, signals []IndicatorSignal) error {
	query := `
        INSERT INTO binance.indicator_signal (open_time, symbol_id, indicator_id, period, volume, vol_avg, vol3_avg)
        VALUES (:open_time, :symbol_id, :indicator_id, :period, :volume, :vol_avg, :vol3_avg)
        ON CONFLICT DO NOTHING
    `
	_, err := db.NamedExec(query, signals)
	return err
}

func (t *ticker.Ticker) generateSignals(symbolId int32, indSignal TGenIndicatorSignal, signalChannel chan<- IndicatorSignal) {
	// check if input ranges are valid
	if int(indSignal.IndicatorType) > 1024 {
		log.Fatalf("invalid indicator type exceeds 1024: %s", indSignal.IndicatorType)
	}
	if indSignal.MaxLongTerm >= 1<<11 {
		log.Fatalf("invalid longTerm value: %d exceeds 2048", indSignal.MaxLongTerm)
	}
	if indSignal.ShortTermDiv != 0 {
		maxShortTerm := indSignal.MaxLongTerm * indSignal.ShortTermMulMax / indSignal.ShortTermDiv
		if maxShortTerm >= 1<<10 {
			log.Fatalf("invalid shortTerm value: %d exceeds 1024", maxShortTerm)
		}
	}
	for longTerm := indSignal.MinLongTerm; longTerm <= indSignal.MaxLongTerm; longTerm++ {
		// check min..max < longTerm
		// we need one more element to calculate two following moving average: 0..n and 1..n+1
		longTermKLines := t.GetKLines(indSignal.PeriodIndex, indSignal.PeriodMinutes, longTerm+1)
		if longTermKLines == nil {
			continue
		}
		// get time, volume from the last candle
		kl := &longTermKLines[longTerm]
		openTime := kl.OpenTime
		volume := kl.Volume
		volAvg := klines.VolumeAvg(longTermKLines[1:])
		vol3Avg := klines.VolumeAvg(longTermKLines[longTerm-3+1 : longTerm+1])
		var minShortTerm, maxShortTerm int
		if indSignal.ShortTermDiv != 0 {
			minShortTerm = longTerm * indSignal.ShortTermMulMin / indSignal.ShortTermDiv
			maxShortTerm = longTerm * indSignal.ShortTermMulMax / indSignal.ShortTermDiv
		}
		for shortTerm := minShortTerm; shortTerm <= maxShortTerm; shortTerm++ {
			signal := indSignal.IndicatorFunc(longTermKLines, []int{longTerm, shortTerm})
			if signal != TradeNone {
				indicatorId := int32((int(indSignal.IndicatorType)<<10+longTerm)<<12 + shortTerm)
				if signal == TradeSell {
					indicatorId = -indicatorId
				}
				signalChannel <- IndicatorSignal{
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

// GenerateSignals generates indicator signals for a given symbol using the provided
// TGenIndicatorSignals, and inserts them into a database using a given context and SQLx database pointer.
func (t *ticker.Ticker) GenerateSignals(ctx context.Context, db *sqlx.DB, symbolId int32) error {
	var signals []IndicatorSignal
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
	signalChannel := make(chan IndicatorSignal, 1024)
	waitSignals.Add(1)
	go func() {
		defer waitSignals.Done()
		for signal := range signalChannel {
			signals = append(signals, signal)
		}
	}()

	concurrentRoutines := make(chan struct{}, runtime.NumCPU())
	var wg sync.WaitGroup
	for _, indicator := range getIndicatorsList() {
		if indicator.MaxLongTerm <= t.position+1 {
			// wait free slot for execution or cancelling event
			select {
			case <-ctx.Done():
				break
			case concurrentRoutines <- struct{}{}: // take a slot
				wg.Add(1)
				go func() {
					t.generateSignals(symbolId, indicator, signalChannel)
					<-concurrentRoutines // release the slot
					wg.Done()
				}()
			}
		}
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
	return MaxLongTerm * ticker.PeriodMinutes[len(ticker.PeriodMinutes)-1]
}
