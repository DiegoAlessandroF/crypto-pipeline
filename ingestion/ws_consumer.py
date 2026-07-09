import json
import websocket
from kafka import KafkaProducer


SOCKET_URL = "wss://stream.binance.us:9443/stream?streams=btcusdt@trade/ethusdt@trade/solusdt@trade"


KAFKA_TOPIC = "crypto.prices"
KAFKA_BOOTSTRAP = "localhost:9092"

producer = KafkaProducer(
    bootstrap_servers=KAFKA_BOOTSTRAP,
    key_serializer=lambda k: k.encode("utf-8"),
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
)


def on_message(ws, message):
    data = json.loads(message)
    trade = data["data"]
    symbol = trade["s"]
    producer.send(KAFKA_TOPIC, key=symbol, value=trade)
    print(f"Publicado {symbol}: {trade['p']}")


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
