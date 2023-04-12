package generate_sets

type IntFloat struct {
	N int
	D float64
}

func CartesianProductIntFloat(ints []int, floats []float64) []IntFloat {
	intFloats := make([]IntFloat, 0, len(ints)*len(floats))
	for _, n := range ints {
		for _, d := range floats {
			intFloats = append(intFloats, IntFloat{N: n, D: d})
		}
	}
	return intFloats
}
