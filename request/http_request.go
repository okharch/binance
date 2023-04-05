package request

import (
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"strconv"
	"time"
)

const UserAgent = "okharch/binance"

func GetRequest(ctx context.Context, url string, expectedWeight int) ([]byte, error) {
	// Create a new HTTP request with the constructed URL
	waitRateLimit(ctx, expectedWeight, url)
	for { // loop in a case of Retry-After
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
		if err != nil {
			return nil, err
		}
		// Set the User-Agent header to identify your application
		req.Header.Set("User-Agent", UserAgent)
		// Make the HTTP request
		log.Printf("request %s", url)
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			return nil, err
		}
		defer res.Body.Close()
		// Adjust the current weight based on the API response headers
		rateLimit := adjustRateLimit(res.Header)
		log.Printf("used 1m rate: %d (%s)", rateLimit, url)
		// Check if the response status code is 429 (Too Many Requests)
		if res.StatusCode == 429 {
			// If so, wait for the Retry-After header value and retry the request
			retryAfterStr := res.Header.Get("Retry-After")
			retryAfter, err := strconv.Atoi(retryAfterStr)
			if err != nil {
				return nil, err
			}
			d := time.Duration(retryAfter) * time.Second
			log.Printf("waiting %v before retry %s", d, url)
			time.Sleep(d)
			continue
		}
		// Check if the response status code is 418 (IP banned for too many requests)
		if res.StatusCode == 418 {
			return nil, fmt.Errorf("IP is banned for too many requests")
		}
		// Check if the response status code is not 200 (OK)
		if res.StatusCode != 200 {
			return nil, fmt.Errorf("API returned status code %d", res.StatusCode)
		}
		// Read the response body as a byte slice
		body, err := ioutil.ReadAll(res.Body)

		return body, err
	}
}
