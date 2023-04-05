package request

import (
	"context"
	"log"
	"net/http"
	"strconv"
	"sync"
	"time"
)

/*
This subsystem is used to manage the rate at which requests are made to an API that has usage limits. The waitRateLimit function is used to ensure that the rate limit is not exceeded by waiting if the current weight plus the weight of the current request exceeds the weight limit (defined by the weightLimit constant). The function waits until enough time has passed to stay within the limit, and then adds the weight of the current request to the current weight and updates the last update time.

The adjustRateLimit function is used to adjust the current weight based on the headers from the API response. This function takes an http.Header parameter that contains the headers from the API response, and adjusts the current weight based on the x-mbx-used-weight and x-mbx-used-weight-1m headers. If the x-mbx-used-weight-1m header exceeds the weight limit, the current weight is reset to zero. If the x-mbx-used-weight-1m header is greater than the current weight, the current weight is updated to the value of the x-mbx-used-weight-1m header. Otherwise, the x-mbx-used-weight header is subtracted from the current weight.

The subsystem uses a single sync.Mutex to protect access to the current weight and last update time, which are global variables. The waitRateLimit function blocks other goroutines until the weight limit is satisfied, and the adjustRateLimit function updates the current weight and last update time. By using this subsystem, the rate at which requests are made to the API can be managed and the usage limits can be respected.
*/

const weightLimit = 1200

var currentWeight int
var lastUpdate time.Time
var rMu sync.Mutex

func waitRateLimit(ctx context.Context, supposedWeight int, url string) {
	// Wait if the current weight plus the supposed weight exceeds the weight limit
	rMu.Lock()
	defer rMu.Unlock()

	// reset currentWeight if no updates for more than a minute
	for currentWeight+supposedWeight > weightLimit {
		if time.Since(lastUpdate) > time.Minute {
			currentWeight = 0
			lastUpdate = time.Now()
			continue
		}
		waitTime := time.Second
		rMu.Unlock()
		log.Printf("waiting %v before requesting %s", waitTime, url)
		select {
		case <-ctx.Done():
			return
		case <-time.After(waitTime):
		}
		rMu.Lock()
	}

	// Add the supposed weight to the current weight and update the last update time
	currentWeight += supposedWeight
}

func adjustRateLimit(headers http.Header) int {
	// Adjust the current weight based on the headers from the API response
	usedWeight1m, err := strconv.Atoi(headers.Get("x-mbx-used-weight-1m"))
	if err != nil {
		usedWeight1m = 0
	}

	rMu.Lock()
	defer rMu.Unlock()

	// Update the current weight based on the headers
	currentWeight = usedWeight1m
	lastUpdate = time.Now()
	return usedWeight1m
}
