/*
DECLARE

	-- The Binance API endpoint https://api.binance.com/api/v3/ticker/24hr returns the
	-- 24-hour trading data for each symbol. The data is a
	-- rolling window of 24 hours,
	-- starting from the current time and going back 24 hours.
	-- This means that the data is continuously updated, and the
	-- 24-hour window keeps moving as time progresses.
*/
package main

import (
	"database/sql"
	"fmt"
	_ "github.com/lib/pq"
	"io"
	"net/http"
	"os"
)

func main() {
	// Fetch the ticker data from the Binance API.
	resp, err := http.Get("https://api.binance.com/api/v3/ticker/24hr")
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to fetch ticker data: %v\n", err)
		os.Exit(1)
	}
	defer resp.Body.Close()

	// Read the response body.
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to read response body: %v\n", err)
		os.Exit(1)
	}

	// Connect to the database using the TBOTS_DB environment variable.
	db, err := sql.Open("postgres", os.Getenv("TBOTS_DB"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to connect to database: %v\n", err)
		os.Exit(1)
	}
	defer db.Close()

	// Call the stored procedure to update the ticker data.
	if _, err := db.Exec("call binance.update_ticker_data($1)", body); err != nil {
		fmt.Fprintf(os.Stderr, "failed to update ticker data: %v\n", err)
		os.Exit(1)
	}
}
