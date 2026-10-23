@loan
Feature: Simulacion de prestamo y evaluacion de riesgo

  # Criterio 5 del enunciado.
  #
  # Hallazgos:
  #   H5: en JSON responseDate viene como epoch millis; ISO-8601 solo en XML.
  #   H7: el motor NUNCA aprueba (ni con 100% de cuota inicial).
  #   H7b: downPayment = 0 devuelve 400 con un mensaje interno de Java, no de negocio.
  #   H9: una cuenta origen inexistente devuelve 200 "denegado", no 400/404.
  #
  # Nota: NO se envia customerId. En esta version ese parametro provoca un NPE (H8).

  Background:
    * def ctx = karate.callSingle('classpath:org/udea/parabank/common/bootstrap.feature').response
    * url baseUrl
    * configure headers = { Accept: 'application/json' }

  @smoke @publico
  Scenario: El contrato del prestamo es coherente en JSON
    Given path 'requestLoan'
    And param loanAmount = 1000
    And param downPayment = 100
    And param fromAccountId = ctx.fromAccountId
    When method post
    Then status 200
    And match header Content-Type contains 'application/json'

    * def prestamo = response
    * match prestamo.responseDate == '#number'
    * match prestamo.loanProviderName == '#string'
    * match prestamo.approved == '#boolean'

    # El proveedor es el procesador SOAP: evidencia de la integracion
    * match prestamo.loanProviderName contains 'WSDL'

    # La fecha debe ser reciente (epoch millis, menos de 5 minutos de desfase)
    * def ahora = Java.type('java.lang.System').currentTimeMillis()
    * assert Math.abs(ahora - prestamo.responseDate) < 300000

    # Coherencia: si se deniega -> hay mensaje y no hay cuenta;
    #             si se aprueba -> debe existir una cuenta.
    * assert prestamo.approved ? prestamo.accountId != null : (prestamo.message != null && prestamo.accountId == null)

  @regression @publico
  Scenario: La fecha del prestamo en XML cumple ISO-8601
    # El criterio pide ISO-8601; en JSON ParaBank usa epoch millis (H5),
    # asi que la validacion estricta se hace negociando XML.
    * configure headers = { Accept: 'application/xml' }
    Given path 'requestLoan'
    And param loanAmount = 1000
    And param downPayment = 100
    And param fromAccountId = ctx.fromAccountId
    When method post
    Then status 200
    And match header Content-Type contains 'xml'

    * def fecha = karate.xmlPath(response, '//responseDate')
    * match fecha == '#regex \\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}\\.\\d{3}Z'
    * def aprobado = karate.xmlPath(response, '//approved')
    * match aprobado == 'false'
    * print 'responseDate ISO:', fecha

  @regression @local-only
  Scenario Outline: La respuesta mantiene la coherencia en el perfil "<perfil>"
    Given path 'requestLoan'
    And param loanAmount = <monto>
    And param downPayment = <cuota>
    And param fromAccountId = ctx.fromAccountId
    When method post
    Then status 200
    * def r = response
    * match r.approved == '#boolean'
    * assert r.approved ? r.accountId != null : (r.message != null && r.accountId == null)

    Examples:
      | perfil       | monto | cuota |
      | cuota minima | 1000  | 1     |
      | cuota 10%    | 1000  | 100   |
      | cuota 50%    | 1000  | 500   |
      | cuota 100%   | 1000  | 1000  |
      | monto alto   | 5000  | 500   |
