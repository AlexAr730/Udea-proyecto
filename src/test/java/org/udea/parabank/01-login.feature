@login
Feature: Autenticacion y ciclo de vida de la sesion

  Background:
    * url baseUrl
    * header Accept = 'application/json'

  @smoke
  Scenario: Login valido devuelve el cliente en JSON
    Given path 'login', user, pass
    When method get
    Then status 200
    And match header Content-Type contains 'application/json'
    And match response ==
    """
    {
       "id": '#number',
       "firstName": '#string',
       "lastName": '#string',
       "address": {
            "street": '#string',
            "city": '#string',
            "state": '#string',
            "zipCode": '#string'
        },
       "phoneNumber": '#string',
       "ssn": '#string'
    }
    """
    And match response.id == customerId

  @smoke
  Scenario: La UI crea la sesion y entrega la cookie JSESSIONID
    # El endpoint /login no emite Set-Cookie: la sesion nace en la UI.
    Given url appUrl
    And path 'index.htm'
    And header Accept = 'text/html'
    When method get
    Then status 200
    And match header Set-Cookie contains 'JSESSIONID='
    * def session = responseCookies.JSESSIONID
    * assert session.value != null
    * print 'JSESSIONID obtenido:', session.value

  @regression
  Scenario: El login respeta la negociacion de contenido en XML
    Given path 'login', user, pass
    And header Accept = 'application/xml'
    When method get
    Then status 200
    And match header Content-Type contains 'xml'
    # response es un objeto XML: se consulta con XPath, no con contains
    * match karate.xmlPath(response, '/customer/firstName') == 'John'
    * def idXml = karate.xmlPath(response, '/customer/id')
    * match idXml == '' + customerId

  @regression
  Scenario: Credenciales invalidas devuelven un error controlado
    # Comportamiento real de ParaBank: 400 text/plain (no 401 JSON).
    Given path 'login', user, 'clave-incorrecta'
    When method get
    Then status 400
    And match header Content-Type contains 'text/plain'
    And match response contains 'Invalid username and/or password'
