@transfer
Feature: Transferencia atomica y consistencia del libro mayor

  # Criterio 3 del enunciado.
  #
  # Estrategia para no depender de valores absolutos (el demo es compartido):
  #   1. Leer saldos ANTES.
  #   2. Anotar el id maximo de transaccion ANTES.
  #   3. Transferir.
  #   4. Comparar DELTAS en centavos (evita errores de punto flotante).
  #   5. Buscar los movimientos NUEVOS (id > maximo anterior) y validar tipo/monto.
  #
  # Escenario @publico: tolerante (puede haber actividad ajena en el demo).
  # Escenario @local-only: estricto (exige exactamente un Debit y un Credit).

  Background:
    * def ctx = karate.callSingle('classpath:org/udea/parabank/common/bootstrap.feature').response
    * url baseUrl
    # configure headers aplica a TODOS los requests del escenario.
    # El step "header" se pierde despues del primer request en Karate 1.3.1.
    * configure headers = { Accept: 'application/json' }
    * def monto = 5
    # Helpers de JavaScript
    * def cent = function(n){ return Math.round(n * 100) }
    * def ultimoId = function(ts){ return ts.reduce(function(m,t){ return t.id > m ? t.id : m }, 0) }

  @smoke @publico
  Scenario: Transferir mueve el saldo y registra el movimiento en el destino
    # --- Saldos antes ---
    Given path 'accounts', ctx.fromAccountId
    When method get
    Then status 200
    * def origenAntes = response.balance

    Given path 'accounts', ctx.toAccountId
    When method get
    Then status 200
    * def destinoAntes = response.balance

    # --- Id maximo del destino antes de transferir ---
    Given path 'accounts', ctx.toAccountId, 'transactions'
    When method get
    Then status 200
    * def maxDestinoAntes = ultimoId(response)

    # --- Transferencia ---
    Given path 'transfer'
    And param fromAccountId = ctx.fromAccountId
    And param toAccountId = ctx.toAccountId
    And param amount = monto
    When method post
    Then status 200
    And match response contains 'Successfully transferred'

    # --- Saldos despues: delta exacto en centavos ---
    Given path 'accounts', ctx.fromAccountId
    When method get
    * def origenDespues = response.balance

    Given path 'accounts', ctx.toAccountId
    When method get
    * def destinoDespues = response.balance

    * assert cent(origenAntes) - cent(monto) == cent(origenDespues)
    * assert cent(destinoAntes) + cent(monto) == cent(destinoDespues)

    # --- Libro mayor del destino: debe existir un Credit nuevo por el monto ---
    Given path 'accounts', ctx.toAccountId, 'transactions'
    When method get
    Then status 200
    * def nuevasDestino = response.filter(function(t){ return t.id > maxDestinoAntes })
    * def creditos = nuevasDestino.filter(function(t){ return t.type == 'Credit' && t.amount == monto })
    * assert creditos.length >= 1
    * match creditos[0].description contains 'Transfer'
    * print 'Credit nuevo:', creditos[0]

  @regression @local-only
  Scenario: La transferencia es atomica y no genera duplicados
    # --- Estado antes ---
    Given path 'accounts', ctx.fromAccountId, 'transactions'
    When method get
    Then status 200
    * def maxOrigenAntes = ultimoId(response)

    Given path 'accounts', ctx.toAccountId, 'transactions'
    When method get
    Then status 200
    * def maxDestinoAntes = ultimoId(response)

    # --- Transferencia ---
    Given path 'transfer'
    And param fromAccountId = ctx.fromAccountId
    And param toAccountId = ctx.toAccountId
    And param amount = monto
    When method post
    Then status 200

    # --- Movimientos nuevos en cada libro ---
    Given path 'accounts', ctx.fromAccountId, 'transactions'
    When method get
    Then status 200
    * def nuevasOrigen = response.filter(function(t){ return t.id > maxOrigenAntes })

    Given path 'accounts', ctx.toAccountId, 'transactions'
    When method get
    Then status 200
    * def nuevasDestino = response.filter(function(t){ return t.id > maxDestinoAntes })

    # Exactamente uno en cada lado (sin duplicados ni movimientos huerfanos)
    * assert nuevasOrigen.length == 1
    * assert nuevasDestino.length == 1

    * match nuevasOrigen[0].type == 'Debit'
    * match nuevasOrigen[0].amount == monto
    * match nuevasOrigen[0].description contains 'Transfer'

    * match nuevasDestino[0].type == 'Credit'
    * match nuevasDestino[0].amount == monto
    * match nuevasDestino[0].description contains 'Transfer'

    # Son transacciones distintas y por el mismo monto
    * assert nuevasOrigen[0].id != nuevasDestino[0].id
    * assert nuevasOrigen[0].amount == nuevasDestino[0].amount
    * print 'Debit:', nuevasOrigen[0]
    * print 'Credit:', nuevasDestino[0]
