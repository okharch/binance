package request

import (
	"context"
	"io/ioutil"
	"log"
	"net/http"
)

const UserAgent = "okharch/binance"

func GetRequest(ctx context.Context, url string, expectedWeight int) ([]byte, error) {
	// Create a new HTTP request with the constructed URL
	for { // loop in a case of Retry-After
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
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			return nil, err
		}
		defer res.Body.Close()
		// Adjust the current weight based on the API response headers
		retry, err := handleApiLimit(res, url)
		if err != nil {
			return nil, err
		}
		if retry {
			continue
		}
		// Read the response body as a byte slice
		body, err := ioutil.ReadAll(res.Body)

		return body, err
	}
}
