package download

import (
	"context"
	"fmt"
	"github.com/okharch/binance/request"
	"time"

	"github.com/jmoiron/sqlx"
)

func fetchAndUploadKlines(ctx context.Context, symbol WatchSymbol, period string, db *sqlx.DB) error {
	// Fetch the last close time from PostgreSQL database
	// If lastCloseTime is null, set it to 2 years ago
	if symbol.StartOpenTime == 0 {
		symbol.StartOpenTime = time.Now().AddDate(-2, 0, 0).UnixNano() / int64(time.Millisecond)
	}
	// Calculate the next open time
	nextOpenTime := symbol.StartOpenTime
	// Continue downloading klines until rows affected is less than limit
	for {
		// Construct the URL to fetch klines from Binance API
		limit := 1000 // maximum number of klines to download per request
		url := fmt.Sprintf("https://www.binance.com/api/v3/klines?symbol=%s&interval=%s&startTime=%d&limit=%d", symbol.Symbol, period, nextOpenTime, limit)
		body, err := request.GetRequest(ctx, url, db)
		// Upload the klines to PostgreSQL database
		var rowsAffected int
		var lastCloseTime int64
		rows := db.QueryRow("SELECT * FROM binance.upload_klines($1, $2, $3)", symbol.Symbol, period, body)
		err = rows.Scan(&lastCloseTime, &rowsAffected)
		if err != nil {
			return err
		}
		// If rows affected is less than limit, exit the loop
		if rowsAffected < limit {
			break
		}
		// Update the next open time to the last close time plus one
		nextOpenTime = lastCloseTime + 1
	}
	return nil
}
