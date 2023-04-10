package indicators

const IndicatorBits = 8

type IndicatorType int

const (
	IndicatorTypeMAC IndicatorType = iota
	IndicatorTypeMACD
	IndicatorTypeBollinger
)

type IndicatorSignal struct {
	OpenTime    int32 `db:"open_time" json:"open_time"`
	SymbolId    int32 `db:"symbol_id" json:"symbol_id"`
	IndicatorId int32 `db:"indicator_id" json:"indicator_id"`
	Periods     int16 `db:"periods" json:"periods"` // bits of periods that triggered signal
}

func (it IndicatorType) String() string {
	switch it {
	case IndicatorTypeMAC:
		return "MAC"
	case IndicatorTypeMACD:
		return "MACD"
	case IndicatorTypeBollinger:
		return "Bollinger"
	default:
		return ""
	}
}
