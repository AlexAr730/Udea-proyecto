@accounts
Feature: Integridad de datos en la consulta de cuentas

  # Criterio 2 del enunciado: contrato estricto + coherencia de los datos.
  #
  # Hallazgo H3: ParaBank no solo devuelve CHECKING/SAVINGS; tambien existen
  # cuentas de tipo LOAN (se crean al aprobar un prestamo).
  #
  # Los escenarios @publico son seguros contra el demo compartido; el @local-only
  # exige una base limpia y se excluye cuando se corre con -Dkarate.tags='@publico'.

  Background:
    * def ctx = karate.callSingle('classpath:org/udea/parabank/common/bootstrap.feature').response
    * url baseUrl
    * header Accept = 'application/json'

  @smoke @publico
  Scenario: El contrato de cada cuenta se cumple estrictamente
    Given path 'customers', ctx.customerId, 'accounts'
    When method get
    Then status 200
    And match header Content-Type contains 'application/json'

    * def cuentas = response
    * match cuentas == '#array'
    * assert cuentas.length >= 2

    # Contrato: exactamente estos 4 campos y estos tipos
    * match each cuentas == { id: '#number', customerId: '#number', type: '#string', balance: '#number' }

    # id debe ser entero (Long), no un decimal
    * def idsNoEnteros = cuentas.filter(function(c){ return !Number.isInteger(c.id) })
    * match idsNoEnteros == []

    # type debe pertenecer al enum real (incluye LOAN, ver H3)
    * def tiposInvalidos = cuentas.filter(function(c){ return ['CHECKING','SAVINGS','LOAN'].indexOf(c.type) < 0 })
    * match tiposInvalidos == []

    # El customerId de cada cuenta debe coincidir con el de la URI
    * def otrosClientes = cuentas.filter(function(c){ return c.customerId != ctx.customerId })
    * match otrosClientes == []

    # Las cuentas del contexto (bootstrap) deben existir en la respuesta
    * assert cuentas.some(function(c){ return c.id == ctx.fromAccountId })
    * assert cuentas.some(function(c){ return c.id == ctx.toAccountId })

  @local-only
  Scenario: Ninguna cuenta del dataset tiene saldo negativo (base limpia)
    Given path 'customers', ctx.customerId, 'accounts'
    When method get
    Then status 200
    * def negativas = response.filter(function(c){ return c.balance < 0 })
    * match negativas == []

  @publico
  Scenario: Las cuentas de trabajo tienen saldo no negativo
    # Version portable del criterio: solo exige integridad sobre las cuentas
    # que controla la suite, no sobre todo el dataset compartido.
    Given path 'customers', ctx.customerId, 'accounts'
    When method get
    Then status 200
    * def propiasNegativas = response.filter(function(c){ return (c.id == ctx.fromAccountId || c.id == ctx.toAccountId) && c.balance < 0 })
    * match propiasNegativas == []

  @regression @publico
  Scenario: Un cliente inexistente devuelve un error controlado
    Given path 'customers', 999999, 'accounts'
    When method get
    Then status 400
    And match header Content-Type contains 'text/plain'
    And match response contains 'Could not find customer #999999'
