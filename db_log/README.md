lets develop binance rest api logging subsystem. we will store log entries inhto postgres database. lets create binance_log shema. lets create rest_api_requests in that schema where we store when we sent request, when response came, what were the response status code, what was used weight x-mbx-used-weight-1m, what was the size of response body. thats probably it so far. create table and create some golang code which goes into this section: 		if !waitApiLimit(ctx) {
return nil, nil // context cancelled
}
res, err := http.DefaultClient.Do(req)
if err != nil {
return nil, err
}
defer res.Body.Close()
// Adjust the current weight based on the API response headers
retry, err := handleApiLimit(res, url)
and probably alter handleApiLimit with some additional parameters like when it was going to complete request, when it started request, when it received response. the code for handleApiLimit is here: // handles status codes 429, 418 and headers Retry-After, x-mbx-used-weight-1m, x-mbx-used-weight
// in order to behave correctly regarding binance rest API
// url parameter is used for logging only
func handleApiLimit(res *http.Response, url string) (bool, error) {
// Check if the response status code is 429 (Too Many Requests)
waitMu.Lock()
defer waitMu.Unlock()
headers := res.Header
if res.StatusCode == 429 {
// If so, wait for the Retry-After header value and retry the request
retryAfterStr := headers.Get("Retry-After")
retryAfter, err := strconv.Atoi(retryAfterStr)
if err != nil {
return false, err
}
if retryAfter != 0 {
d := time.Duration(retryAfter) * time.Second
waitUntil = time.Now().Add(d)
log.Printf("retry when %s", waitUntil)
return true, nil
}
}
// Check if the response status code is 418 (IP banned for too many requests)
if res.StatusCode == 418 {
return false, fmt.Errorf("IP is banned for too many requests")
}
// Check if the response status code is not 200 (OK)
if res.StatusCode != 200 {
return false, fmt.Errorf("API returned status code %d", res.StatusCode)
}

	// Adjust the current weight based on the headers from the API response
	usedWeight := headers.Get("x-mbx-used-weight")
	var err error
	usedWeight1m, err = strconv.Atoi(headers.Get("x-mbx-used-weight-1m"))
	if err != nil {
		usedWeight1m = 100
	}
	log.Printf("used weight:%s, weight 1m:%d, %s", usedWeight, usedWeight1m, url)
	return false, nil
}
provide all alterations to existing code, as short as possible