package klines

import (
	"context"
	"fmt"
	"github.com/gorilla/websocket"
	"log"
	"strings"
)

func getBinanceWebSocketKlines(ctx context.Context, symbols []string) (<-chan string, error) {
	// Create a channel to receive messages
	msgChan := make(chan string)

	// Build the WebSocket URL for the specified symbols and intervals
	url := fmt.Sprintf("wss://stream.binance.com:9443/stream?streams=%s",
		strings.Join(buildStreamList(symbols), "/"))

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
				msgChan <- string(message)
			}
		}
	}()

	return msgChan, nil
}

func buildStreamList(symbols []string) []string {
	var streams []string
	for _, symbol := range symbols {
		stream := fmt.Sprintf("%s@kline_1m", strings.ToLower(symbol))
		streams = append(streams, stream)
	}
	return streams
}
