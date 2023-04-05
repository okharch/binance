package klines

import (
	"context"
	"fmt"
	"github.com/jmoiron/sqlx"
	"log"
	"sync"
)

func fetchWatchedSymbols(db *sqlx.DB) ([]string, error) {
	var symbols []string
	err := db.Select(&symbols, "SELECT symbol FROM binance.watch_symbols")
	if err != nil {
		return nil, fmt.Errorf("failed to fetch symbols: %v", err)
	}
	return symbols, nil
}

const LimitCoroutines = 3

func DownloadWatchedSymbols(ctx context.Context, db *sqlx.DB, wg *sync.WaitGroup) error {
	defer wg.Done()

	// Fetch the list of watched symbols
	symbols, err := fetchWatchedSymbols(db)
	if err != nil {
		return fmt.Errorf("failed to fetch symbols: %v", err)
	}

	// Start downloading and updating klines for each symbol concurrently, up to LimitCoroutines at a time
	ch := make(chan string)
	for i := 0; i < LimitCoroutines; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for symbol := range ch {
				if err := fetchAndUploadKlines(ctx, symbol, "1m", db); err != nil {
					log.Printf("failed to fetch and upload klines for symbol %s: %v", symbol, err)
				}
			}
		}()
	}
	for _, symbol := range symbols {
		select {
		case <-ctx.Done():
			break
		default:
			ch <- symbol
		}
	}
	close(ch)

	// Start updating klines from web sockets in a separate goroutine
	wg.Add(1)
	go updateFromWebSockets(ctx, db, symbols, wg)

	return nil
}

func updateFromWebSockets(ctx context.Context, db *sqlx.DB, symbols []string, wg *sync.WaitGroup) {
	defer wg.Done()

	updateKlines, err := getBinanceWebSocketKlines(ctx, symbols)
	if err != nil {
		log.Printf("failed to init update klines from web socker: %s", err)
	}

	// Listen for kline update messages and update the klines table
	for msg := range updateKlines {
		if _, err := db.Exec("SELECT binance.update_klines_from_ws($1)", msg); err != nil {
			log.Printf("failed to update klines from kline stream: %v", err)
		}
	}
}
