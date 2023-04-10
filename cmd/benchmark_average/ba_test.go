package main

import (
	"math/rand"
	"testing"
)

const SliceSize = 128

func BenchmarkAverage(b *testing.B) {
	// Generate a slice of SliceSize random float64 numbers
	numbers := make([]float64, SliceSize)
	for i := 0; i < len(numbers); i++ {
		numbers[i] = rand.Float64()
	}

	// Run the benchmark for the average function
	for i := 0; i < b.N; i++ {
		average(numbers)
	}
}

func BenchmarkAverageInt(b *testing.B) {
	// Generate a slice of SliceSize random integers
	numbers := make([]int, SliceSize)
	for i := 0; i < len(numbers); i++ {
		numbers[i] = rand.Intn(100)
	}

	// Run the benchmark for the AverageInt function
	for i := 0; i < b.N; i++ {
		AverageInt(numbers)
	}
}

func BenchmarkAverageIntShl(b *testing.B) {
	// Generate a slice of SliceSize random integers
	numbers := make([]int, SliceSize)
	for i := 0; i < len(numbers); i++ {
		numbers[i] = rand.Intn(100)
	}

	// Run the benchmark for the AverageInt function
	for i := 0; i < b.N; i++ {
		AverageIntShl(numbers, 7)
	}
}

func BenchmarkAverageInt32(b *testing.B) {
	// Generate a slice of SliceSize random int32 values
	numbers := make([]int32, SliceSize)
	for i := 0; i < len(numbers); i++ {
		numbers[i] = rand.Int31n(100)
	}

	// Run the benchmark for the AverageInt32 function
	for i := 0; i < b.N; i++ {
		AverageInt32(numbers)
	}
}
