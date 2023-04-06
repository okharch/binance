package request

import (
	"context"
	"fmt"
	"github.com/okharch/binance/db_log"
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

const weightLimit = 350

var usedWeight1m int
var waitUntil time.Time
var waitMu sync.RWMutex
var walMu sync.Mutex

// waits until waitUntil (set by handler or Retry-After) or next minute
// if usedWeight1m>usedWeight1m
// url parameter is used for logging only
// returns true if context was not cancelled
func waitApiLimit(ctx context.Context) bool {
	waitMu.RLock()
	var wld time.Duration
	// check either minute usage or waitUntil
	if usedWeight1m > weightLimit {
		nextMinute := time.Now().Truncate(time.Minute).Add(time.Minute)
		if nextMinute.After(waitUntil) {
			waitUntil = nextMinute
		}
	} else {
		wld = time.Millisecond * 50 //calculateWaitLimitDuration(usedWeight1m, weightLimit)
	}
	waitUntilCopy := waitUntil
	waitMu.RUnlock()
	// lock waiting slot. everybody has to wait at least wld
	walMu.Lock()
	defer walMu.Unlock()
	if time.Now().After(waitUntilCopy) && wld > 0 {
		waitUntilCopy = time.Now().Add(wld)
		log.Printf("wld %v until %v", wld, waitUntilCopy)
	}
	return waitUntilTimeOrCancelled(ctx, waitUntilCopy)
}

// handles status codes 429, 418 and headers Retry-After, x-mbx-used-weight-1m, x-mbx-used-weight
// in order to behave correctly regarding binance rest API
// url parameter is used for logging only
func handleApiLimit(res *http.Response, url string, comeTime, requestTime time.Time) (
	lr db_log.ApiRequestLogRecord, retry bool, err error) {
	// Check if the response status code is 429 (Too Many Requests)
	waitMu.Lock()
	defer waitMu.Unlock()
	headers := res.Header
	lr.ResponseStatusCode = res.StatusCode
	lr.ResponseTime = time.Now()
	lr.ComeTime = comeTime
	lr.RequestTime = requestTime
	lr.RequestUrl = url
	if res.StatusCode == 429 {
		// If so, wait for the Retry-After header value and retry the request
		lr.RetryAfter, err = strconv.Atoi(headers.Get("Retry-After"))
		if err != nil {
			return
		}
		retry = lr.RetryAfter != 0
		if retry {
			d := time.Duration(lr.RetryAfter) * time.Second
			waitUntil = time.Now().Add(d)
			return
		}
	}
	// Check if the response status code is 418 (IP banned for too many requests)
	if res.StatusCode == 418 {
		err = fmt.Errorf("IP is banned for too many requests")
		return
	}
	// Check if the response status code is not 200 (OK)
	if res.StatusCode != 200 {
		err = fmt.Errorf("API returned status code %d", res.StatusCode)
		return
	}

	// Adjust the current weight based on the headers from the API response
	lr.UsedWeight, err = strconv.Atoi(headers.Get("x-mbx-used-weight-1m"))
	if err != nil {
		usedWeight1m = 100
	}
	return
}

func waitUntilTimeOrCancelled(ctx context.Context, t time.Time) bool {
	log.Printf("wait until %v", t)
	select {
	case <-ctx.Done():
		return false
	case <-time.After(time.Until(t)):
		return true
	}
}
