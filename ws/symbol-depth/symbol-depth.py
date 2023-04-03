import os
import sys
import json
import websocket
import psycopg2
from urllib.parse import urlparse

conn = None


def on_open(ws, symbols):
    print("WebSocket opened.")
    # Subscribe to the order book for each trading pair in the list
    for symbol in symbols:
        payload = {
            "method": "SUBSCRIBE",
            "params": [f"{symbol}@depth"],
            "id": 1
        }
        ws.send(json.dumps(payload))


def on_message(ws, message):
    # Use the message to update the binance db
    global conn
    with conn.cursor() as cur:
        cur.callproc("binance.process_depth_update", [message])
        result = cur.fetchone()
        if result:
            symbol, event_time, asks_affected, bids_affected = result
            print(f"Symbol: {symbol}, Event time: {event_time}, Asks affected: {asks_affected}, Bids affected: {bids_affected}")
        conn.commit()


def on_error(ws, error):
    print(f"Error: {error}")


def on_close(ws):
    print("WebSocket closed.")


def main(symbols=['btcusdt','solusdt']):
    db_url = os.environ["TBOTS_DB"]
    print("DB:",db_url)
    global conn
    conn = psycopg2.connect(db_url)

    websocket_url = "wss://stream.binance.com:9443/ws"
    ws = websocket.WebSocketApp(
        websocket_url,
        on_open=lambda ws: on_open(ws, symbols),
        on_message=on_message,
        on_error=on_error,
        on_close=on_close
    )
    ws.run_forever()


if __name__ == "__main__":
    if len(sys.argv) > 1:
        main(sys.argv[1:])
    else:
        main()
