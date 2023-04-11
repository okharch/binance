package main

import (
	"context"
	"errors"
	"fmt"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/okharch/binance/klines"
	"github.com/okharch/binance/ticker"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func GetDB(envVarName string) (*sqlx.DB, error) {
	url := os.Getenv(envVarName)
	if url == "" {
		return nil, errors.New("missing environment variable " + envVarName)
	}
	db, err := sqlx.Open("postgres", url)
	if err != nil {
		return nil, err
	}
	if err := db.Ping(); err != nil {
		return nil, err
	}
	return db, nil
}

func main() {
	// Connect to the database.
	db, err := GetDB("TBOTS_DB")
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}
	defer db.Close()

	// Create a context that can be cancelled with Ctrl-C.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Start a goroutine that listens for Ctrl-C signals and cancels the context.
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigCh
		cancel()
	}()

	// Fetch the symbols from the watch_symbols table.
	symbols, err := fetchSymbols(ctx, db)
	if err != nil {
		log.Fatalf("failed to fetch symbols: %v", err)
	}

	// For each symbol, fetch 1-minute klines and generate signals.
	for _, symbol := range symbols {
		// Fetch 1-minute klines for the symbol.
		kLineData, err := klines.FetchKLineDataFromDBSincePeriodsBefore(db, symbol, int64(ticker.GetMaxMinutes()))
		if err != nil {
			log.Printf("failed to fetch klines for symbol %s: %v", symbol, err)
			continue
		}

		// Create a ticker using the 1-minute klines.
		t := ticker.NewTicker(kLineData.Data)
		ticks := t.GetTicksChannel(ctx)
		for tick := range ticks {
			log.Printf("generating signals for %d: %d", symbol, tick.OpenTime)
			// Generate signals using the ticker.
			if err := t.GenerateSignals(ctx, db, symbol); err != nil {
				log.Printf("failed to generate signals for symbol %s: %v", symbol, err)
				continue
			}
		}
	}
}

// fetchSymbols fetches the symbols from the watch_symbols table.
func fetchSymbols(ctx context.Context, db *sqlx.DB) ([]int32, error) {
	var symbols []int32
	err := db.SelectContext(ctx, &symbols, "SELECT symbol_id FROM binance.watch_symbols")
	if err != nil {
		return nil, fmt.Errorf("failed to fetch symbols: %w", err)
	}
	return symbols, nil
}
