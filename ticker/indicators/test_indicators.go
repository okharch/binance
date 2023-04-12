package indicators

import "github.com/okharch/binance/ticker"

/*
This interface defines a single method CheckSignals that takes three parameters:

t: A pointer to a Ticker object that contains the historical price data for the security being analyzed.

periodIndex: An integer index that represents the current period being analyzed in the Ticker object.

periodMinutes: An integer that represents the duration of each period in minutes.

The CheckSignals method returns a slice of int64 values that represent the different
parameter combinations and indicator IDs that triggered a signal during the current period.
Each int64 value can be packed with the indicator ID and parameter values using
bitwise operations or other packing methods, depending on the specific needs of the implementation.
*/
type TestIndicator interface {
	CheckSignals(t *ticker.Ticker, periodIndex int, periodMinutes int) []int64
}
