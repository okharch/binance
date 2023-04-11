package klines

type MapKLineFunc = func(kl *KLineEntry) float64

func VolumeAvg(kLines []KLineEntry) float64 {
	if len(kLines) == 0 {
		return 0
	}
	total := float64(0.0)
	for _, kl := range kLines {
		total += kl.Volume
	}
	return total / float64(len(kLines))
}
