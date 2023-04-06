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
		lr, retry, errApiLimit := handleApiLimit(res, url, comeTime, requestTime)
		// Read the response body as a byte slice
		if !retry {
			body, err := ioutil.ReadAll(res.Body)
			lr.ResponseSize = len(body)
			if errLog := db_log.LogApiRequest(db, lr); errLog != nil {
				log.Printf("Failed to insert API request log: %v", errLog)
			}
			if errApiLimit != nil && err == nil {
				err = errApiLimit
			}
			return body, err
		}
		if errApiLimit != nil {
			return nil, errApiLimit
		}
	}
}
