@ignore
Feature: Crear cuenta de apoyo para las pruebas

  # Solo se usa en local. En el demo publico no se crean cuentas.
  # newAccountType: 0 = CHECKING, 1 = SAVINGS.
  # Ojo: en esta version, crear la cuenta mueve 100 desde la cuenta origen.

  Scenario: Crear una cuenta de ahorros
    * url baseUrl
    * header Accept = 'application/json'
    Given path 'createAccount'
    And param customerId = customerId
    And param newAccountType = 1
    And param fromAccountId = fromAccountId
    When method post
    Then status 200
    * def nuevaCuenta = response
    * match nuevaCuenta.type == 'SAVINGS'
    * print 'cuenta creada:', nuevaCuenta
