# ParaBank — Automatización de pruebas de API con Karate

Suite de pruebas de backend para [ParaBank](https://parabank.parasoft.com/parabank/index.htm),
organizada en cinco servicios y ejecutable contra un entorno local reproducible (Docker) o
contra el demo público del curso.

## Requisitos

- Java 17 o superior
- Maven 3.8+
- Docker con Compose v2
- `curl` (lo usan los scripts de infraestructura)

## Inicio rápido

```bash
# 1. Levantar ParaBank en localhost:8080
./scripts/parabank-up.sh

# 2. Verificar que el entorno responde
./scripts/check-local.sh

# 3. Ejecutar la suite
mvn test
```

Reportes:

```bash
xdg-open target/karate-reports/karate-summary.html
xdg-open target/cucumber-html-reports/overview-features.html
```

## Entornos

| Entorno | Cómo se activa | Base URL | Datos |
|---|---|---|---|
| `local` (por defecto) | `mvn test` | `http://localhost:8080/parabank/services/bank` | Se resetean con `cleanDB` |
| `publico` | `mvn test -Dkarate.env=publico -Dkarate.tags='@publico'` | `https://parabank.parasoft.com/parabank/services/bank` | Compartidos, sin escrituras destructivas |

El `cleanDB` solo se ejecuta si `env == local`. **Nunca** debe correrse contra el demo público.

## Cobertura

| Servicio | Feature | Escenarios |
|---|---|---|
| Configuración del entorno | `00-config.feature` | 4 |
| Contexto compartido (bootstrap) | `00-contexto.feature` | 1 |
| Login y sesión | `01-login.feature` | 4 |
| Cuentas | `02-accounts.feature` | 4 |
| Transferencias | `03-transfer.feature` | 2 |
| Bill Pay | `04-billpay.feature` | 1 |
| Préstamos | `05-loan.feature` | 7 |
| Defectos conocidos | `99-known-issues.feature` | 9 (fallan a propósito) |

## Tags

| Tag | Uso |
|---|---|
| `@smoke` | Camino feliz mínimo |
| `@regression` | Casos negativos y de borde |
| `@local-only` | Requiere base limpia (saldos exactos) |
| `@publico` | Seguro contra el demo compartido |
| `@known-issue` | Documenta defectos; excluido por defecto |

```bash
mvn test -Dkarate.tags='@smoke'
mvn test -Dkarate.tags='@accounts'
mvn test -Dkarate.tags='~@known-issue'      # comportamiento por defecto
mvn test -Dkarate.tags='@known-issue'       # evidencia de defectos (falla)
```

## Estructura

```
src/test/java/
├── karate-config.js              # perfiles local/publico, timeouts, credenciales
├── logback-test.xml
└── org/udea/parabank/
    ├── 00-config.feature
    ├── 00-contexto.feature
    ├── 01-login.feature
    ├── 02-accounts.feature
    ├── 03-transfer.feature
    ├── 04-billpay.feature
    ├── 05-loan.feature
    ├── 99-known-issues.feature
    ├── common/                   # helpers reutilizables (reset, login, alta de cuenta, bootstrap)
    └── TestRunnerParallel.java
```

## Infraestructura

```bash
./scripts/parabank-up.sh    # docker compose up + espera activa
./scripts/check-local.sh    # valida Docker, UI, login y endpoint de cuentas
./scripts/reset-db.sh       # cleanDB (bloqueado si la URL no es local)
docker compose down         # apaga y borra el estado
```

## Hallazgos

Los defectos encontrados (Bill Pay inoperante, préstamos que nunca se aprueban, errores
internos filtrados) están documentados en [`HALLAZGOS.md`](HALLAZGOS.md) y automatizados en
`99-known-issues.feature`.
