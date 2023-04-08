package ticker

import (
	"github.com/okharch/binance/klines"
	"log"
	"time"
)

/* for array of length n+2 returns three last moving average value for n */
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

func mac(longTermKLines []klines.KLineEntry, shortTerm int) TradeSignal {
	shortTermKlines := longTermKLines[len(longTermKLines)-shortTerm:]
	s1, s2 := average2(shortTermKlines)
	l1, l2 := average2(longTermKLines)
	log.Printf("s1:%.1f,s2:%.1f,l1:%.1f,l2:%.1f", s1, s2, l1, l2)
	if s1 < 0 || s2 < 0 {
		return TradeNone
	}
	if s1 < s2 && s1 < l1 && s2 > l2 {
		return TradeBuy
	}
	if s1 > s2 && s1 > l1 && s2 < l2 {
		return TradeSell
	}
	return TradeNone
}

func (t *Ticker) MAC(period time.Duration, shortTerm, longTerm int) TradeSignal {
	longTermKLines := t.GetKLines(period, longTerm+2)
	return mac(longTermKLines, shortTerm)
}
