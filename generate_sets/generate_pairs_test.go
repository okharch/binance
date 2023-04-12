package generate_sets

import (
	"testing"
)

func TestMinRatio(t *testing.T) {
	minRatioFunc := MinRatio(2)

	tests := []struct {
		short int
		long  int
		valid bool
	}{
		{5, 10, true},
		{10, 5, false},
		{10, 18, false},
		{10, 20, true},
	}

	for _, tt := range tests {
		if got := minRatioFunc(tt.long, tt.short); got != tt.valid {
			t.Errorf("MinRatio(0.5) for (%d, %d) = %v, want %v", tt.long, tt.short, got, tt.valid)
		}
	}
}

func TestGenerateIntPairs(t *testing.T) {
	minVal := 5
	maxVal := 30
	minRatio := 0.5
	goodPair := MinRatio(minRatio)
	pairs := GenerateIntPairs(minVal, maxVal, goodPair)

	for _, pair := range pairs {
		longAvg, shortAvg := pair[0], pair[1]

		if shortAvg >= longAvg {
			t.Errorf("Invalid pair: shortAvg (%d) >= longAvg (%d)", shortAvg, longAvg)
		}

		if float64(shortAvg)*minRatio > float64(longAvg) {
			t.Errorf("Invalid pair: shortAvg (%d) * minRatio (%f) > longAvg (%d)", shortAvg, minRatio, longAvg)
		}
	}
}
