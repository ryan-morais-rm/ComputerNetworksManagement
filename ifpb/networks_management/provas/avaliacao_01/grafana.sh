docker run -d \
  --name=grafana \
  -p 3000:3000 \
  --restart=unless-stopped \
  grafana/grafana-oss