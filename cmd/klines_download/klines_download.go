package main

import (
	"context"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
	"github.com/okharch/binance/klines/download"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func main() {

	// Set a custom log formatter that includes line numbers
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Create a context that can be cancelled on termination signals
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Create a database connection
	dbURL := os.Getenv("TBOTS_DB")
	if dbURL == "" {
		log.Fatal("TBOTS_DB environment variable is not set")
	}

	db, err := sqlx.Connect("postgres", dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Wait for termination signal
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sigCh
		log.Println("Received termination signal, cancelling context")
		cancel()
	}()

	// Run DownloadWatchedSymbols with context, database connection, and wait group
	err = download.DownloadWatchedSymbols(ctx, db)
	if err != nil {
		log.Fatalf("Failed to download watched symbols: %v", err)
	}

	log.Println("klines_download: exit gracefully")
}
