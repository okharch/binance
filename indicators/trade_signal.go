package indicators

type TradeSignal int

const (
	TradeNone TradeSignal = iota
	TradeBuy
	TradeSell
)
