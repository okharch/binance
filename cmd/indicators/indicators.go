package main

import (
	"context"
	"fmt"
	"github.com/jmoiron/sqlx"
	"log"
	"os"
)

// Define a function to establish a database connection using the TBOTS_DB environment variable
func getDB() (*sqlx.DB, error) {
	db, err := sqlx.Connect("postgres", os.Getenv("TBOTS_DB"))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}
	return db, nil
}

func main() {
	// Establish a database connection
	db, err := getDB()
	if err != nil {
		log.Fatalf("failed to connect to database: %v", err)
	}
	defer db.Close()

	// Retrieve all symbols from binance.klines
	symbols, err := klines.GetSymbols(db)
	if err != nil {
		log.Fatalf("failed to retrieve symbols: %v", err)
	}

	// Generate signals for each symbol
	for _, symbol := range symbols {
		// Retrieve the k-line data for the symbol
		data, err := klines.GetKLines(db, symbol.Symbol, "1m")
		if err != nil {
			log.Printf("failed to retrieve k-line data for %s: %v", symbol.Symbol, err)
			continue
		}

		// Create a ticker for the k-line data
		ticker := NewTicker(data)

		// Generate signals for the symbol and insert them into the database
		err = ticker.GenerateSignals(context.Background(), db, symbol.SymbolId)
		if err != nil {
			log.Printf("failed to generate signals for %s: %v", symbol.Symbol, err)
			continue
		}
	}
}
