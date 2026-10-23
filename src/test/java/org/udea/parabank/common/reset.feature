@ignore
Feature: Reset de la base de datos (solo entorno local)

  # Se invoca desde bootstrap.feature y NUNCA debe ejecutarse contra el demo
  # publico: borraria los datos de todos los equipos.

  Scenario: Dejar la base en el estado inicial
    * url baseUrl
    * header Accept = 'application/json'
    Given path 'cleanDB'
    When method post
    Then status 204
