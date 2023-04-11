package indicators

type IndicatorType int

const (
	IndicatorTypeMAC IndicatorType = iota
	IndicatorTypeMACD
	IndicatorTypeBollinger
)

type IndicatorSignal struct {
	OpenTime    int64   `db:"open_time"`
	SymbolId    int32   `db:"symbol_id"`
	IndicatorId int32   `db:"indicator_id"`
	Period      int8    `db:"period"`
	Volume      float64 `db:"volume"`
	VolAvg      float64 `db:"vol_avg"`
	Vol3Avg     float64 `db:"vol3_avg"`
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
