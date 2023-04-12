package generate_sets

import (
	"reflect"
	"testing"
)

func TestGenIntSeq(t *testing.T) {
	start, delta, n := 1, 2, 5
	expected := []int{1, 3, 5, 7, 9}
	sequence := GenIntSeq(start, delta, n)
	if !reflect.DeepEqual(sequence, expected) {
		t.Errorf("GenIntSeq(%d, %d, %d) = %v, expected %v", start, delta, n, sequence, expected)
	}
}

func TestGenFloatSeq(t *testing.T) {
	start, delta := 1.0, 0.5
	n := 5
	expected := []float64{1.0, 1.5, 2.0, 2.5, 3.0}
	sequence := GenFloatSeq(start, delta, n)
	if !reflect.DeepEqual(sequence, expected) {
		t.Errorf("GenFloatSeq(%f, %f, %d) = %v, expected %v", start, delta, n, sequence, expected)
	}
}
