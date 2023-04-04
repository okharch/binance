import websocket
import json

def on_open(ws):
    print("WebSocket opened.")
    payload = {
        "method": "SUBSCRIBE",
        "params": ["!ticker@arr"],
        "id": 1
    }
    ws.send(json.dumps(payload))

def on_message(ws, message):
    #data = json.loads(message)
    print("Ticker update received:", message)

def on_error(ws, error):
    print(f"Error: {error}")

def on_close(ws):
    print("WebSocket closed.")

def main():
    websocket_url = "wss://stream.binance.com:9443/ws"
    ws = websocket.WebSocketApp(
        websocket_url,
        on_open=on_open,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close
    )
    ws.run_forever()

if __name__ == "__main__":
    main()
