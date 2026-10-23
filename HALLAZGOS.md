# Hallazgos — ParaBank

**Fecha:** 23 de octubre de 2026
**Entorno:** ParaBank local (`parasoft/parabank`, Docker) y demo público
(`https://parabank.parasoft.com`). Los hallazgos marcados como *reproducible en ambos*
se verificaron en los dos.
**Evidencia automatizada:** `mvn test -Dkarate.tags='@known-issue'`
(los escenarios fallan a propósito mientras el defecto exista).

## Resumen

| ID | Servicio | Esperado | Real | Severidad |
|---|---|---|---|---|
| H1 | Login | 401 + error JSON | 400 `text/plain` | Media |
| H2 | Login/sesión | `Set-Cookie` en `/login` | Solo la UI emite `JSESSIONID` | Media |
| H3 | Cuentas | Enum `CHECKING/SAVINGS` | También `LOAN` | Baja |
| H4 | Cuentas | Sin saldos negativos | El dataset demo trae negativos | Baja (entorno) |
| H5 | Préstamos | `responseDate` ISO-8601 | JSON: epoch millis | Baja |
| H6 | Bill Pay | 4xx con mensaje de negocio | **500 sin body** | **Crítica** |
| H7 | Préstamos | Aprobar con cuota suficiente | Nunca aprueba | **Alta** |
| H7b | Préstamos | 400 con mensaje descriptivo | 400 con error interno de Java | **Alta** |
| H8 | Préstamos | Aceptar `customerId` | NPE (`intCompact`) | Media |
| H9 | Préstamos | 400/404 si la cuenta no existe | 200 "denegado por fondos" | Media |

**Criterio de severidad**

- **Crítica:** el servicio no funciona para ningún caso de uso.
- **Alta:** una regla de negocio produce un resultado incorrecto o se filtra un error interno.
- **Media:** desviación de contrato que obliga al cliente a manejar casos no documentados.
- **Baja:** inconsistencia de formato o de datos del entorno de demostración.

---

## H1 — Login inválido devuelve 400 en texto plano, no 401 con error JSON

**Criterio del enunciado:** credenciales incorrectas → `401 Unauthorized` con esquema de error
estandarizado.

**Real**

```bash
curl -i -H 'Accept: application/json' \
  https://parabank.parasoft.com/parabank/services/bank/login/john/mala
```

```
HTTP/2 400
content-type: text/plain;charset=UTF-8

Invalid username and/or password
```

**Impacto:** un cliente que espere distinguir "no autenticado" (401) de "petición mal formada"
(400) no puede hacerlo. No hay cuerpo JSON ni código de error estable.

**Test:** `99-known-issues.feature` → `[H1]`.

---

## H2 — El endpoint de login no emite `Set-Cookie`

**Criterio del enunciado:** extraer y validar `Set-Cookie` con `JSESSIONID` desde
`GET /login/{user}/{pass}`.

**Real:** el login responde 200 sin `Set-Cookie`. El `JSESSIONID` lo crea la interfaz web:

```bash
curl -i https://parabank.parasoft.com/parabank/index.htm
# set-cookie: JSESSIONID=...; Path=/parabank; HttpOnly
```

Además, los endpoints REST funcionan sin la cookie, así que la "sesión" no se exige en la API.

**Impacto:** el ciclo de vida de sesión descrito en el criterio no existe tal cual. El test lo
documenta y valida la cookie en el punto real donde se emite.

**Test:** `01-login.feature` → *"La UI crea la sesion y entrega la cookie JSESSIONID"*.

---

## H3 — Existen cuentas de tipo `LOAN`

**Criterio del enunciado:** `type` ∈ {`CHECKING`, `SAVINGS`}.

**Real:** al aprobar (o intentar) préstamos se crean cuentas con `"type":"LOAN"`.

```json
[{"id":12345,"customerId":12212,"type":"CHECKING","balance":-2003099.98},
 {"id":30882,"customerId":12212,"type":"LOAN","balance":100.00}]
```

**Impacto:** un cliente que valide el enum estrictamente rechazaría cuentas válidas del propio
sistema. El contrato del enunciado está incompleto, no la aplicación.

**Test:** `02-accounts.feature` (enum ampliado a `LOAN`).

---

## H4 — El dataset de demostración contiene saldos negativos

**Criterio del enunciado:** ningún `balance` negativo.

**Real:** el demo público tiene cuentas con `-2003099.98`, y el `initializeDB` local también
crea cuentas negativas (`-2300.00`, `-100.00`). Solo `cleanDB` deja un estado positivo.

**Impacto:** el criterio no se puede exigir sobre datos compartidos. Se valida de dos formas:
estricta con `cleanDB` (`@local-only`) y portable sobre las cuentas que controla la suite
(`@publico`).

**Test:** `02-accounts.feature` → escenarios de saldos.

---

## H5 — `responseDate` es epoch millis en JSON

**Criterio del enunciado:** fecha válida en ISO-8601.

**Real**

```json
{"responseDate": 1792778456226, ...}
```

```xml
<responseDate>2026-10-23T18:00:55.956Z</responseDate>
```

**Impacto:** el formato depende de la negociación de contenido. La validación ISO-8601 se hace
con `Accept: application/xml`; en JSON se valida como número y se comprueba que sea reciente.

**Test:** `05-loan.feature` → escenarios JSON y XML.

---

## H6 — Bill Pay devuelve 500 sin cuerpo (servicio inoperante)

**Criterio del enunciado:** errores de negocio (400/422) con mensajes descriptivos; nunca 500.

**Real:** `POST /billpay?accountId=13344` con un payload válido devuelve **500 y body vacío**.
Se reproduce en local y en el demo público, con monto válido, cero, negativo, cuenta inexistente
y saldo insuficiente.

```
HTTP/2 500
content-length: 0
```

**Impacto:** el servicio no se puede usar. No hay validación de entrada ni esquema de error.
No se filtra una traza, pero tampoco hay información para el cliente.

**Test:** `04-billpay.feature` (resiliencia) y `99-known-issues.feature` → `[H6]` × 5 casos.

---

## H7 — El motor de préstamos nunca aprueba

**Criterio del enunciado:** la aprobación depende del monto y la cuota inicial.

**Real:** con `loanAmount=1000` y `downPayment` de 1, 100, 500, 1000 o 5000, siempre:

```json
{"approved": false,
 "message": "error.insufficient.funds.for.down.payment",
 "accountId": null}
```

Incluso pagando el 100 % por adelantado. La cuenta de origen tenía saldo suficiente.

**Impacto:** la rama "aprobado" es inalcanzable; no se puede validar la regla de negocio.

**Test:** `99-known-issues.feature` → `[H7]`.

---

## H7b — Cuota inicial 0 devuelve un error interno de Java

**Criterio del enunciado:** mensajes descriptivos y esquema de errores.

**Real**

```bash
curl -X POST '.../requestLoan?loanAmount=1000&downPayment=0&fromAccountId=13344'
```

```
HTTP/1.1 400
Content-Type: text/plain;charset=UTF-8

Cannot read field "intCompact" because "<parameter1>" is null
```

**Impacto:** se expone un mensaje interno de la implementación (BigDecimal) en lugar de una
validación de negocio ("la cuota inicial debe ser mayor que cero").

**Test:** `99-known-issues.feature` → `[H7b]`.

---

## H8 — `customerId` en `requestLoan` provoca un NPE

**Real:** agregar `customerId=12212` al request produce el mismo error interno:

```
Cannot read field "intCompact" because "<parameter1>" is null
```

**Impacto:** un parámetro que el cliente podría enviar (y que el nombre sugiere como válido)
rompe el servicio. La suite no lo envía y el hallazgo queda documentado.

**Test:** no automatizado (se documenta para no fijar el defecto en el contrato).

---

## H9 — Cuenta de origen inexistente devuelve 200 "denegado"

**Real**

```bash
curl -X POST '.../requestLoan?loanAmount=1000&downPayment=100&fromAccountId=999999'
# 200 {"approved":false,"message":"error.insufficient.funds.for.down.payment",...}
```

**Impacto:** se enmascara un error de datos (cuenta inexistente) como una decisión de negocio.
El cliente no puede distinguir "no hay fondos" de "la cuenta no existe".

**Test:** `99-known-issues.feature` → `[H9]`.

---

## Cómo reproducir todo

```bash
./scripts/parabank-up.sh
mvn test                                   # suite verde (23 escenarios)
mvn test -Dkarate.tags='@known-issue'      # 9 fallos: evidencia de H1, H6, H7, H7b, H9
mvn test -Dkarate.env=publico -Dkarate.tags='@publico'   # contra el demo del profesor
```

Los reportes quedan en `target/karate-reports/` y `target/cucumber-html-reports/`.
