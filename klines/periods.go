package klines

import (
	"fmt"
	"time"
)

func Period2Duration(period string) (time.Duration, error) {
	switch period {
	case "1m":
		return time.Minute, nil
	case "3m":
		return 3 * time.Minute, nil
	case "5m":
		return 5 * time.Minute, nil
	case "15m":
		return 15 * time.Minute, nil
	case "30m":
		return 30 * time.Minute, nil
	case "1h":
		return time.Hour, nil
	case "2h":
		return 2 * time.Hour, nil
	case "4h":
		return 4 * time.Hour, nil
	case "6h":
		return 6 * time.Hour, nil
	case "8h":
		return 8 * time.Hour, nil
	case "12h":
		return 12 * time.Hour, nil
	case "1d":
		return 24 * time.Hour, nil
	case "3d":
		return 3 * 24 * time.Hour, nil
	case "1w":
		return 7 * 24 * time.Hour, nil
	case "1M":
		return 30 * 24 * time.Hour, nil
	default:
		return 0, fmt.Errorf("invalid period: %s", period)
	}
}

func Duration2Period(duration time.Duration) string {
	switch duration {
	case time.Minute:
		return "1m"
	case 3 * time.Minute:
		return "3m"
	case 5 * time.Minute:
		return "5m"
	case 15 * time.Minute:
		return "15m"
	case 30 * time.Minute:
		return "30m"
	case time.Hour:
		return "1h"
	case 2 * time.Hour:
		return "2h"
	case 4 * time.Hour:
		return "4h"
	case 6 * time.Hour:
		return "6h"
	case 8 * time.Hour:
		return "8h"
	case 12 * time.Hour:
		return "12h"
	case 24 * time.Hour:
		return "1d"
	case 3 * 24 * time.Hour:
		return "3d"
	case 7 * 24 * time.Hour:
		return "1w"
	case 30 * 24 * time.Hour:
		return "1M"
	default:
		return "1m"
	}
}
