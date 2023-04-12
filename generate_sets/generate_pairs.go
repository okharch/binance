package generate_sets

func MinRatio(ratio float64) func(int, int) bool {
	return func(long, short int) bool {
		return short < long && float64(short)*ratio <= float64(long)
	}
}

func GenerateIntPairs(minVal, maxVal int, goodPair func(int, int) bool) [][2]int {
	pairs := make([][2]int, 0)

	for longAvg := minVal; longAvg <= maxVal; longAvg++ {
		for shortAvg := minVal; shortAvg <= maxVal; shortAvg++ {
			if goodPair(shortAvg, longAvg) && shortAvg < longAvg {
				pairs = append(pairs, [2]int{longAvg, shortAvg})
			}
		}
	}

	return pairs
}
