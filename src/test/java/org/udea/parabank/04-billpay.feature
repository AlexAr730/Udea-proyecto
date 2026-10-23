@billpay
Feature: Pago de servicios (Bill Pay)

  # Criterio 4 del enunciado.
  #
  # Hallazgo H6: POST /billpay devuelve 500 con body vacio, incluso con datos
  # validos, tanto en local como en el demo publico. No existe el 400 con
  # mensaje descriptivo que pide el enunciado.
  #
  # Por eso:
  #   - Aqui queda la prueba VERDE: responde, no cuelga y no filtra trazas.
  #   - En 99-known-issues.feature queda la prueba del comportamiento IDEAL
  #     (400 + esquema de error), que falla mientras el defecto exista.
  #
  # Casos cubiertos en el known-issue: monto 0, negativo, cuenta inexistente,
  # saldo insuficiente y monto valido.

  Background:
    * def ctx = karate.callSingle('classpath:org/udea/parabank/common/bootstrap.feature').response
    * url baseUrl
    * configure headers = { Accept: 'application/json', 'Content-Type': 'application/json' }
    * def factura = function(monto){ return { name: 'EPM', address: 'Calle 1', city: 'Medellin', state: 'ANT', zipCode: '050001', phoneNumber: '3001234567', accountNumber: '999', amount: monto } }

  @smoke @publico
  Scenario: El endpoint responde y no expone trazas internas
    Given path 'billpay'
    And param accountId = ctx.fromAccountId
    * def cuerpoPago = factura(5)
    And request cuerpoPago
    When method post
    * match responseStatus == '#number'
    * assert responseTime < 15000
    * def cuerpo = response == null ? '' : response.toString()
    * match cuerpo !contains 'Exception'
    * match cuerpo !contains 'at org.'
    * match cuerpo !contains 'java.'
    * print 'billpay -> status', responseStatus, '| body:', cuerpo
