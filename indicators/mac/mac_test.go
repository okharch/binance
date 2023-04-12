package mac

import (
	"github.com/okharch/binance/klines"
	"github.com/okharch/binance/ticker/indicators"
	"testing"
)

func TestMAC(t *testing.T) {
	tests := []struct {
		shortTerm int
		expected  indicators.TradeSignal
		prices    []float64
	}{
		{5, indicators.TradeBuy, []float64{20, 21, 11, 18, 10, 10, 14, 13, 15, 18}},
		{5, indicators.TradeSell, []float64{10, 11, 12, 13, 20, 16, 15, 14, 13, 9}},
	}

	for _, test := range tests {
		prices := test.prices
		kLines := make([]klines.KLineEntry, len(prices))

		for i, price := range prices {
			kLines[i] = klines.KLineEntry{ClosePrice: price}
		}
		signal := mac(kLines, test.shortTerm)
		if signal != test.expected {
			t.Errorf("MAC signal error: expected %v, but got %v", test.expected, signal)
		}
	}
}
