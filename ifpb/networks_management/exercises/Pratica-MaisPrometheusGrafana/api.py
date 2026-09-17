import random
import time
from flask import Flask, jsonify

app = Flask(__name__)

# Rota 1 (/status): Health check simples com resposta rápida
@app.route('/status', methods=['GET'])
def status():
    return jsonify({"status": "API Online"}), 200

# Rota 2 (/processar): Simula processamento pesado com latência aleatória (0.5 a 2 segundos)
@app.route('/processar', methods=['GET'])
def processar():
    atraso = random.uniform(0.5, 2.0)
    time.sleep(atraso)
    return jsonify({"message": "Processamento concluído", "delay_seconds": round(atraso, 2)}), 200

# Rota 3 (/falha): Simula comportamento caótico com 50% de chance de erro HTTP 500
@app.route('/falha', methods=['GET'])
def falha():
    if random.random() < 0.5:
        return jsonify({"error": "Internal Server Error simulado"}), 500
    return jsonify({"message": "Requisição bem-sucedida por sorte"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)