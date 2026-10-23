#!/usr/bin/env bash
# Deja la base de ParaBank en el estado mínimo conocido:
#   John (customer 12212) con una sola cuenta: 13344 CHECKING, saldo 5022.93.
#
# SEGURIDAD: este script SOLO funciona contra localhost. Nunca debe ejecutarse
# contra el demo público (parabank.parasoft.com): borraría los datos de todos.
#
# Uso:
#   ./scripts/reset-db.sh

set -euo pipefail

BASE_URL="${PARABANK_URL:-http://localhost:8080}"

case "$BASE_URL" in
    http://localhost* | http://127.0.0.1*) ;;
    *)
        echo "✗ cleanDB bloqueado: '$BASE_URL' no es local." >&2
        exit 1
        ;;
esac

code=$(curl -s -o /dev/null -w '%{http_code}' \
    -X POST "$BASE_URL/parabank/services/bank/cleanDB")

if [[ "$code" != "204" ]]; then
    echo "✗ cleanDB respondió HTTP $code" >&2
    exit 1
fi

echo "✓ Base limpia (HTTP $code). Estado actual:"
curl -s -H 'Accept: application/json' \
    "$BASE_URL/parabank/services/bank/customers/12212/accounts"
echo
