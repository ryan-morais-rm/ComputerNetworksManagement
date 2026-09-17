while true; do
    curl -s http://127.0.0.1:5000/status > /dev/null &
    curl -s http://127.0.0.1:5000/processar > /dev/null &
    curl -s http://127.0.0.1:5000/falha > /dev/null &
    
    sleep 0.5
    echo "Enviando requisições..."
done