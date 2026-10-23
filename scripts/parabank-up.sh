#!/usr/bin/env bash
# Levanta ParaBank en Docker y espera a que la aplicación responda por HTTP.
#
# Uso:
#   ./scripts/parabank-up.sh
#   PARABANK_URL=http://localhost:9090 ./scripts/parabank-up.sh   # si se cambia el puerto
#
# Sale con código 0 solo cuando /parabank/index.htm responde 2xx.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_URL="${PARABANK_URL:-http://localhost:8080}"
TIMEOUT="${PARABANK_TIMEOUT:-90}"

cd "$ROOT_DIR"

echo "→ Levantando contenedor..."
docker compose up -d

echo "→ Esperando $BASE_URL/parabank/index.htm (máx. ${TIMEOUT}s)"
for ((i = 1; i <= TIMEOUT; i++)); do
    # -L sigue el 302 inicial; stderr silenciado: mientras Tomcat arranca
    # es normal recibir "connection reset"
    if curl -fsSL -o /dev/null "$BASE_URL/parabank/index.htm" 2>/dev/null; then
        echo "✓ ParaBank disponible en ${i}s"
        break
    fi
    if ((i == TIMEOUT)); then
        echo "✗ Timeout esperando ParaBank. Últimos logs:"
        docker compose logs --tail=40 parabank
        exit 1
    fi
    sleep 1
done

# Un contenedor nuevo arranca con la base vacía (sin john/demo). Se siembra
# solo si hace falta: si ya hay datos, NO se toca.
if ! curl -fsS -o /dev/null -H 'Accept: application/json' \
    "$BASE_URL/parabank/services/bank/login/john/demo" 2>/dev/null; then
    echo "→ Base sin inicializar; sembrando dataset demo..."
    code=$(curl -s -o /dev/null -w '%{http_code}' -X POST \
        "$BASE_URL/parabank/services/bank/cleanDB")
    [[ "$code" == "204" ]] || { echo "✗ No se pudo sembrar la base (HTTP $code)"; exit 1; }
    echo "✓ Base inicializada"
fi

echo "✓ Entorno listo en $BASE_URL"
