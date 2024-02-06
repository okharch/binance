package download

import (
	"context"
	"fmt"
	"github.com/gorilla/websocket"
	"log"
	"strings"
)

// getBinanceWebSocketKlines subscribes to the Binance WebSocket API to receive klines for the specified symbols and intervals
// it returns a channel that receives messages from the WebSocket connection
func getBinanceWebSocketKlines(ctx context.Context, symbols []WatchSymbol, period KLinePeriod) (<-chan []byte, error) {
	// Create a channel to receive messages
	msgChan := make(chan []byte)

	// Build the WebSocket URL for the specified symbols and intervals
	url := fmt.Sprintf("wss://stream.binance.com:9443/stream?streams=%s",
		strings.Join(buildStreamList(symbols, period), "/"))

	// Connect to the Binance WebSocket API
	conn, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to WebSocket: %v", err)
	}

	// Start a goroutine to read messages from the WebSocket connection
	go func() {
		defer close(msgChan)
		for {
			select {
			case <-ctx.Done():
				return
			default:
				_, message, err := conn.ReadMessage()
				if err != nil {
					log.Printf("error reading web socket stream %s: %s", url, err)
					return
				}
				msgChan <- message
			}
		}
	}()

	return msgChan, nil
}

// buildStreamList constructs a list of stream names for the specified symbols and intervals
// which are used to subscribe to the Binance WebSocket API
func buildStreamList(symbols []WatchSymbol, period KLinePeriod) (streamList []string) {
	for _, symbol := range symbols {
		// Construct the stream name for the symbol and interval, e.g. "btcusdt@kline_1m"
		stream := fmt.Sprintf("%s@kline_%s", strings.ToLower(symbol.Symbol), period)
		streamList = append(streamList, stream)
	}
	return
}
