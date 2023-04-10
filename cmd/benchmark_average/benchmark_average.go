package main

import "fmt"

func average(numbers []float64) float64 {
	total := 0.0
	count := len(numbers)

	for _, number := range numbers {
		total += number
	}

	if count == 0 {
		return 0
	}

	return total / float64(count)
}

func AverageInt(numbers []int) int {
	total := 0
	count := len(numbers)

	for _, number := range numbers {
		total += number
	}

	if count == 0 {
		return 0
	}

	return total / count
}

func AverageIntShl(numbers []int, shift int) int {
	total := 0

	for _, number := range numbers {
		total += number
	}

	return total >> shift
}

func AverageInt32(numbers []int32) int32 {
	var total int
	count := len(numbers)

	for _, number := range numbers {
		total += int(number)
	}

	if count == 0 {
		return 0
	}

	return int32(total / count)
}

func main() {
	numbers := []float64{1.2, 3.4, 5.6, 7.8, 9.0}
	fmt.Printf("The average of %v is %v\n", numbers, average(numbers))
	numbersI := []int{1, 2, 3, 4, 5}
	fmt.Printf("The average of %v is %v\n", numbersI, AverageInt(numbersI))
}
