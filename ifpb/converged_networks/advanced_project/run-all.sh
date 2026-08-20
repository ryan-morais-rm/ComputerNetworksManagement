#!/usr/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RUNS="${RUNS:-10}"
KEEP_UP="${KEEP_UP:-0}"
SKIP_BUILD="${SKIP_BUILD:-0}"

DATA_DIR="$SCRIPT_DIR/results"
mkdir -p "$DATA_DIR"
LOG_FILE="$DATA_DIR/run.log"
: > "$LOG_FILE"

log() {
  local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
  echo "$msg" | tee -a "$LOG_FILE"
}

COMPOSE="docker compose"

cleanup() {
  if [ "$KEEP_UP" != "1" ]; then
    log "Derrubando containers (KEEP_UP=0)..."
    $COMPOSE down >> "$LOG_FILE" 2>&1 || true
  else
    log "KEEP_UP=1: containers permanecem ativos."
  fi
}
trap cleanup EXIT

log "=== Bateria completa de testes HTTP vs WebSocket ==="
log "RUNS=$RUNS  |  resultados em: $DATA_DIR"

if [ "$SKIP_BUILD" != "1" ]; then
  log "Construindo imagens (docker compose build)..."
  $COMPOSE build >> "$LOG_FILE" 2>&1
fi

log "Subindo containers (docker compose up -d)..."
$COMPOSE up -d >> "$LOG_FILE" 2>&1

log "Aguardando o servidor responder em http://localhost:3000/health ..."
ATTEMPTS=0
until curl -sf http://localhost:3000/health > /dev/null 2>&1; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge 30 ]; then
    log "ERRO: servidor não respondeu após 30 tentativas. Abortando."
    $COMPOSE logs server >> "$LOG_FILE" 2>&1
    exit 1
  fi
  sleep 1
done
log "Servidor pronto."

run_scenario() {
  local protocol="$1"
  local direction="$2"
  local copies="$3"
  local overhead="$4"
  local label="protocol=$protocol direction=$direction copies=$copies overhead=$overhead"

  log ">>> Rodando cenário: $label"
  if $COMPOSE exec -T client node benchmark.js \
      --protocol="$protocol" \
      --direction="$direction" \
      --copies="$copies" \
      --overhead="$overhead" \
      --runs="$RUNS" \
      --out="/results/${protocol}-${direction}-oh${overhead}.csv" \
      >> "$LOG_FILE" 2>&1; then
    log "    OK: $label"
  else
    log "    FALHOU: $label (veja $LOG_FILE para detalhes)"
  fi
}

FULL_SWEEP="1,3,10,30,100,300,1000,3000"
OVERHEAD_LEVELS="0 10 50 100 200 300"

# --- 4.2 / 4.3 — HTTP e WebSocket, sem TLS, varrendo 1..3000 cópias ---
log "--- Etapa 1/3: HTTP e WebSocket sem TLS (seções 4.2 e 4.3) ---"
for protocol in http ws; do
  for direction in send receive; do
    run_scenario "$protocol" "$direction" "$FULL_SWEEP" 0
  done
done

# --- 4.6 — HTTPS e WSS (TLS), mesma varredura, para comparar com o item acima ---
log "--- Etapa 2/3: HTTPS e WSS com TLS (seção 4.6) ---"
for protocol in https wss; do
  for direction in send receive; do
    run_scenario "$protocol" "$direction" "$FULL_SWEEP" 0
  done
done

# --- 4.5 — Overhead de cabeçalhos HTTP extras, 100 cópias fixas ---
log "--- Etapa 3/3: Overhead de cabeçalhos HTTP (seção 4.5) ---"
for direction in send receive; do
  for overhead in $OVERHEAD_LEVELS; do
    run_scenario "http" "$direction" 100 "$overhead"
  done
done

log "Consolidando todos os CSVs em summary.csv ..."
$COMPOSE exec -T client node summarize.js >> "$LOG_FILE" 2>&1

log "=== Bateria completa finalizada ==="
log "Arquivos gerados em: $DATA_DIR"
ls -la "$DATA_DIR" | tee -a "$LOG_FILE"

log "Resumo consolidado: $DATA_DIR/summary.csv"
log "Log completo desta execução: $LOG_FILE"