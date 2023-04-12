package mac

import (
	"github.com/okharch/binance/klines"
	"github.com/okharch/binance/ticker/indicators"
)

/* for array of length n+1 returns two last moving average value for n */
func average2(klines []klines.KLineEntry) (avg1, avg2 float64) {
	sum := 0.0
	n := len(klines) - 1
	if n <= 0 {
		avg1 = -1
		return
	}
	for _, kLine := range klines[:n] {
		sum += kLine.ClosePrice
	}
	avg1 = sum / float64(n)
	sum += klines[n].ClosePrice - klines[0].ClosePrice
	avg2 = sum / float64(n)
	return
}

/*
1. Moving Average Crossover:
- TradeBuy when a shorter-term moving average crosses above a longer-term moving average.
- TradeSell when the shorter-term moving average crosses below the longer-term moving average.
- Klines data can be used to calculate the moving averages.
*/

func mac(longTermKLines []klines.KLineEntry, shortTerm int) indicators.TradeSignal {
	shortTermKlines := longTermKLines[len(longTermKLines)-shortTerm:]
	s1, s2 := average2(shortTermKlines)
	l1, l2 := average2(longTermKLines)
	//log.Printf("s1:%.1f,s2:%.1f,l1:%.1f,l2:%.1f", s1, s2, l1, l2)
	if s1 < 0 || s2 < 0 {
		return indicators.TradeNone
	}
	if s1 < s2 && s1 < l1 && s2 > l2 {
		return indicators.TradeBuy
	}
	if s1 > s2 && s1 > l1 && s2 < l2 {
		return indicators.TradeSell
	}
	return indicators.TradeNone
}

func MAC(kLines []klines.KLineEntry, params []int) indicators.TradeSignal {
	longTerm := params[0]
	shortTerm := params[1]
	return mac(kLines[:longTerm], shortTerm)
}
