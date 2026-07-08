import json
import websocket


SOCKET_URL = "wss://stream.binance.us:9443/stream?streams=btcusdt@trade/ethusdt@trade/solusdt@trade"


def on_message(ws, message):
    data = json.loads(message)
    trade = data["data"]
    print(f"{trade['s']}: {trade['p']}")


def on_error(ws, error):
    print(f"Erro: {error}")

def on_close(ws, close_status_code, close_msg):
    print("Conexão fechada")

def on_open(ws):
    print("Conexão aberta — recebendo trades...")


if __name__ == "__main__":
    ws = websocket.WebSocketApp(
        SOCKET_URL,
        on_open=on_open,
        on_message=on_message,
        on_error=on_error,
        on_close=on_close,
    )
    ws.run_forever()
