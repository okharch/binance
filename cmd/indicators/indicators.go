package main

import (
	"context"
	"github.com/jmoiron/sqlx"
	"github.com/okharch/binance/klines"
	"github.com/okharch/binance/ticker"
	"log"
	"os"
	"time"
)

func mac(ctx context.Context, period time.Duration, ticker *ticker.Ticker, params []int) {
	for kLine := range ticker.GetTicksChannel(ctx) {
		tradeSignal := ticker.MAC(period, params[0],params[1])
		if tradeSignal != ticker.None
	}
}

var indicators = map[string]func(context.Context,*ticker.Ticker, []int){
	"mac": mac,
}

func main() {
	var db *sqlx.DB

	// connect to postgresql db using url from envTBOTS_DB

	// get indicator name like "mac" from command line $1
	symbol := os.Args[1]
	iFunc := indicators[os.Args[2]]
	var params []int
	// get its numeric parameters into slice from $2..$n
	// os.Args[2..] convert to int and create params slice []int
	//params := os.Args[3:]
	...
	// download all data for SOLUSDT period 1 minute
	kd, err := klines.FetchKLineDataFromDBSincePeriodsBefore(db, "SOLUSDT", 60*24*365)
	if err != nil {
		log.Fatalf("was not able to fetch 1m history for %s: %s ", symbol, err)
	}

	// call ifFunc with parameters
	iFunc(kd,params)
}
