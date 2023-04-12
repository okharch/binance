package generate_sets

import (
	"reflect"
	"testing"
)

func TestCartesianProductIntFloat(t *testing.T) {
	ints := []int{1, 2}
	floats := []float64{1.0, 2.0, 3.0}
	expected := []IntFloat{
		{1, 1.0},
		{1, 2.0},
		{1, 3.0},
		{2, 1.0},
		{2, 2.0},
		{2, 3.0},
	}
	intFloats := CartesianProductIntFloat(ints, floats)
	if !reflect.DeepEqual(intFloats, expected) {
		t.Errorf("CartesianProductIntFloat(%v, %v) = %v, expected %v", ints, floats, intFloats, expected)
	}
}
