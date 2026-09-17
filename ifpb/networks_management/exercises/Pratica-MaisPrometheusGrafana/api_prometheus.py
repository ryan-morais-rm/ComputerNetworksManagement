import random
import time
from flask import Flask, jsonify, Response
from prometheus_client import Counter, Gauge, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# Contador
REQUESTS = Counter(
    'http_requests_total', 
    'Total de requisições recebidas', 
    ['endpoint'] # Label para filtrar qual rota foi acessada
)

# Gauge
IN_PROGRESS = Gauge(
    'requisicoes_ativas_processamento', 
    'Requisições na rota /processar em andamento'
)

# A) Rota de Métricas
@app.route('/metrics', methods=['GET'])
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


# Rota 1 (/status)
@app.route('/status', methods=['GET'])
def status():
    # Incrementa o Counter passando o nome desta rota na label
    REQUESTS.labels(endpoint='/status').inc()
    
    return jsonify({"status": "API Online"}), 200


# Rota 2 (/processar)
@app.route('/processar', methods=['GET'])
def processar():
    # Incrementa o Counter de requisições recebidas
    REQUESTS.labels(endpoint='/processar').inc()
    
    # Início do processamento: sobe o Gauge (+1)
    IN_PROGRESS.inc()
    
    try:
        atraso = random.uniform(0.5, 2.0)
        time.sleep(atraso)
        return jsonify({"message": "Processamento concluído", "delay_seconds": round(atraso, 2)}), 200
    finally:
        # Fim do processamento (mesmo se der erro): desce o Gauge (-1)
        IN_PROGRESS.dec()


# Rota 3 (/falha)
@app.route('/falha', methods=['GET'])
def falha():
    # Incrementa o Counter passando o nome desta rota na label
    REQUESTS.labels(endpoint='/falha').inc()
    
    if random.random() < 0.5:
        return jsonify({"error": "Internal Server Error simulado"}), 500
    return jsonify({"message": "Requisição bem-sucedida por sorte"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)