package macd

type MACDIndicator struct {
	FastPeriod   int
	SlowPeriod   int
	SignalPeriod int
}

func (m *MACDIndicator) CheckSignals(t *Ticker, periodIndex int, periodMinutes int) []int64 {
	prices := make([]float64, len(t.Prices))
	for i, p := range t.Prices {
		prices[i] = float64(p)
	}

	macdValues, signalValues, _ := ta.MACD(prices, m.FastPeriod, m.SlowPeriod, m.SignalPeriod)
	lastMacd := macdValues[len(macdValues)-1]
	lastSignal := signalValues[len(signalValues)-1]

	if lastMacd > lastSignal {
		// Bullish signal
		signal := (int64(m.FastPeriod) << 32) | (int64(m.SlowPeriod) << 16) | int64(m.SignalPeriod)
		return []int64{signal}
	} else if lastMacd < lastSignal {
		// Bearish signal
		signal := (int64(m.FastPeriod) << 32) | (int64(m.SlowPeriod) << 16) | int64(m.SignalPeriod)
		return []int64{signal}
	} else {
		// No signal
		return []int64{}
	}
}
