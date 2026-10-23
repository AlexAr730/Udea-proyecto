@known-issue
Feature: Defectos conocidos de ParaBank

  # Estos escenarios documentan el comportamiento IDEAL del enunciado.
  # Fallan a proposito mientras el defecto exista y NO se ejecutan en la
  # corrida normal (el runner excluye ~@known-issue).
  #
  # Ejecutar solo estos:
  #   mvn test -Dkarate.tags='@known-issue'
  #
  # Si un escenario pasa, el defecto fue corregido: actualizar HALLAZGOS.md
  # y moverlo al feature correspondiente como prueba de regresion.

  Background:
    * url baseUrl
    * configure headers = { Accept: 'application/json', 'Content-Type': 'application/json' }
    * def factura = function(monto){ return { name: 'EPM', address: 'Calle 1', city: 'Medellin', state: 'ANT', zipCode: '050001', phoneNumber: '3001234567', accountNumber: '999', amount: monto } }

  Scenario: [H1] Credenciales invalidas deberian devolver 401 con error JSON
    Given path 'login', user, 'clave-incorrecta'
    When method get
    Then status 401
    And match header Content-Type contains 'application/json'
    And match response == { message: '#string' }

  # H6: el servicio esta caido. El enunciado exige un error de negocio
  # descriptivo (400/422) y nunca un 500 interno. Hoy devuelve 500 sin body.
  Scenario Outline: [H6] Bill Pay deberia responder 4xx con mensaje descriptivo - <caso>
    Given path 'billpay'
    And param accountId = <cuenta>
    * def cuerpoPago = factura(<monto>)
    And request cuerpoPago
    When method post
    Then status 400
    And match response == { message: '#string' }

    Examples:
      | caso               | cuenta | monto  |
      | monto cero         | 13344  | 0      |
      | monto negativo     | 13344  | -50    |
      | cuenta inexistente | 999999 | 10     |
      | saldo insuficiente | 13344  | 999999 |
      | monto valido       | 13344  | 5      |

  # H7: el motor de decision nunca aprueba, ni con el 100% de cuota inicial.
  Scenario: [H7] Un prestamo con 100% de cuota inicial deberia aprobarse
    Given path 'requestLoan'
    And param loanAmount = 1000
    And param downPayment = 1000
    And param fromAccountId = 13344
    When method post
    Then status 200
    And match response.approved == true
    And match response.accountId == '#number'

  # H7b: cuota 0 revienta con un mensaje interno de Java en texto plano.
  Scenario: [H7b] Cuota inicial 0 deberia devolver un error de negocio descriptivo
    Given path 'requestLoan'
    And param loanAmount = 1000
    And param downPayment = 0
    And param fromAccountId = 13344
    When method post
    Then status 400
    And match header Content-Type contains 'application/json'
    And match response == { message: '#string' }

  # H9: una cuenta que no existe deberia rechazarse como tal, no como "sin fondos".
  Scenario: [H9] Una cuenta origen inexistente deberia devolver 400/404
    Given path 'requestLoan'
    And param loanAmount = 1000
    And param downPayment = 100
    And param fromAccountId = 999999
    When method post
    Then status 400
