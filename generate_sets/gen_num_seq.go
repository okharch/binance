package generate_sets

func GenIntSeq(start, delta, n int) []int {
	sequence := make([]int, n)
	for i, acc := 0, start; i < n; i, acc = i+1, acc+delta {
		sequence[i] = acc
	}
	return sequence
}

func GenFloatSeq(start, delta float64, n int) []float64 {
	sequence := make([]float64, n)
	for i, acc := 0, start; i < n; i, acc = i+1, acc+delta {
		sequence[i] = acc
	}
	return sequence
}
