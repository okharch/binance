package request

import (
	"context"
	"github.com/jmoiron/sqlx"
	"github.com/okharch/binance/db_log"
	"io/ioutil"
	"log"
	"net/http"
	"time"
)

const UserAgent = "okharch/binance"

func GetRequest(ctx context.Context, url string, expectedWeight int, db *sqlx.DB) ([]byte, error) {
	// Create a new HTTP request with the constructed URL
	for { // loop in a case of Retry-After
		comeTime := time.Now()
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return nil, err
		}
		// Set the User-Agent header to identify your application
		req.Header.Set("User-Agent", UserAgent)
		// Make the HTTP request
		log.Printf("request %s", url)
		if !waitApiLimit(ctx) {
			return nil, nil // context cancelled
		}
		requestTime := time.Now()
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			return nil, err
		}
		defer res.Body.Close()
		// Adjust the current weight based on the API response headers
		lr, retry, err1 := handleApiLimit(res, url, comeTime, requestTime)
		err = db_log.LogApiRequest(db, lr)
		if err1 != nil {
			return nil, err1
		}
		if err != nil {
			log.Printf("Failed to insert API request log: %v", err)
		}
		if retry {
			continue
		}
		// Read the response body as a byte slice
		body, err := ioutil.ReadAll(res.Body)

		return body, err
	}
}
