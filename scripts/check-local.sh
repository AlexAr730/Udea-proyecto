#!/usr/bin/env bash
# Verifica que el entorno local de ParaBank esté operativo.
# No modifica datos: solo comprueba contenedor, HTTP y API.
#
# Uso:
#   ./scripts/check-local.sh
#
# Código de salida: 0 si todo pasa, 1 si algo falla.

set -uo pipefail

BASE_URL="${PARABANK_URL:-http://localhost:8080}"
failures=0

pass() { printf '  ✓ %s\n' "$1"; }
fail() {
    printf '  ✗ %s\n' "$1"
    failures=$((failures + 1))
}

echo "Verificando entorno local ($BASE_URL)"

# 1. Docker disponible
if docker info >/dev/null 2>&1; then
    pass "Docker responde"
else
    fail "Docker no responde (¿está corriendo el daemon?)"
fi

# 2. Contenedor en ejecución
if docker compose ps --status running --services 2>/dev/null | grep -qx 'parabank'; then
    pass "Contenedor 'parabank' en ejecución"
else
    fail "Contenedor 'parabank' no está corriendo (ejecuta ./scripts/parabank-up.sh)"
fi

# 3. Aplicación web responde
http_code=$(curl -sL -o /dev/null -w '%{http_code}' -m 5 "$BASE_URL/parabank/index.htm")
if [[ "$http_code" == "200" ]]; then
    pass "UI responde 200"
else
    fail "UI respondió $http_code"
fi

# 4. API responde y negocia JSON
login=$(curl -s -m 10 -H 'Accept: application/json' \
    "$BASE_URL/parabank/services/bank/login/john/demo")
if [[ "$login" == *'"id":12212'* ]]; then
    pass "Login de John responde JSON (customer 12212)"
else
    fail "Login inesperado: ${login:0:120}"
fi

# 5. Recurso de cuentas accesible
accounts=$(curl -s -m 10 -H 'Accept: application/json' \
    "$BASE_URL/parabank/services/bank/customers/12212/accounts")
if [[ "$accounts" == \[* ]]; then
    pass "Endpoint de cuentas responde un array"
else
    fail "Cuentas inesperadas: ${accounts:0:120}"
fi

echo
if ((failures == 0)); then
    echo "✓ Entorno OK"
    exit 0
fi

echo "✗ $failures comprobación(es) fallaron"
exit 1
