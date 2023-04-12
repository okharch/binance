package download

import (
	"context"
	"fmt"
	"github.com/jmoiron/sqlx"
	"log"
	"sync"
	"time"
)

type WatchSymbol struct {
	Symbol        string `db:"symbol"`
	StartOpenTime int64  `db:"start_open_time"`
}

func fetchWatchedSymbols(db *sqlx.DB) (result []WatchSymbol, err error) {
	// fetch the most recent symbols updated first,
	// so they have a chance to be updated quickly and move on
	// while others symbols are being updated
	err = db.Select(&result, `
	SELECT b.symbol, coalesce(bb.open_time, 0) as start_open_time
	FROM binance.watch_symbols a inner join binance.exchange_symbols b on a.symbol_id=b.symbol_id
	    left join lateral (
	    select open_time from binance.klines b 
	    where a.symbol_id=b.symbol_id and b.period='1m' 
	    order by 1 desc limit 1
	) bb on true
	order by 2 desc
	`)
	return
}

func DownloadWatchedSymbols(ctx context.Context, db *sqlx.DB) error {

	// Fetch the list of watched symbols
	symbols, err := fetchWatchedSymbols(db)
	if err != nil {
		return fmt.Errorf("failed to fetch symbols: %v", err)
	}

	// Start updating klines from web sockets in a separate goroutine before downloading history
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		updateFromWebSockets(ctx, db, symbols)
	}()

	// Start downloading and updating klines for each symbol concurrently, up to LimitCoroutines at a time
	downloadSymbolsKlinesViaREST(ctx, db, symbols)
	if ctx.Err() != nil {
		return nil
	}
	wg.Wait() // web sockets work until context cancelled
	return nil
}

func downloadSymbolsKlinesViaREST(ctx context.Context, db *sqlx.DB, symbols []WatchSymbol) {
	const LimitCoroutines = 5
	var wg sync.WaitGroup

	ch := make(chan WatchSymbol)
	for i := 0; i < LimitCoroutines; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for symbol := range ch {
				if err := fetchAndUploadKlines(ctx, symbol, "1m", db); err != nil {
					log.Printf("failed to fetch and upload klines for symbol %s: %s", symbol.Symbol, err)
				}
			}
		}()
	}
	for _, symbol := range symbols {
		select {
		case <-ctx.Done():
			break
		default:
			// make pause 100ms before launching new symbols
			time.Sleep(100 * time.Millisecond)
			ch <- symbol
		}
	}
	close(ch)
	wg.Wait()
}

func updateFromWebSockets(ctx context.Context, db *sqlx.DB, symbols []WatchSymbol) {
	updateKlines, err := getBinanceWebSocketKlines(ctx, symbols)
	if err != nil {
		log.Printf("failed to init update klines from web socker: %s", err)
	}

	// Listen for kline update messages and update the klines table
	for msg := range updateKlines {
		var rowsAffected int64
		if err := db.Get(&rowsAffected, "SELECT binance.update_klines_from_ws($1)", msg); err != nil {
			log.Printf("failed to update klines from kline stream: %v", err)
		} else {
			//log.Printf("%d symbols updated from webstream", rowsAffected)
		}
	}
}
