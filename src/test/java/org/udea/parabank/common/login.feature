@ignore
Feature: Login reutilizable

  # Se usa desde bootstrap y desde cualquier feature que necesite una sesion.
  # Devuelve en "result" el cliente y su id.
  # Si se invoca con { user: 'x', pass: 'y' }, esos valores sobreescriben
  # los de karate-config.js.

  Scenario: Autenticar al usuario de configuracion
    * url baseUrl
    * header Accept = 'application/json'
    Given path 'login', user, pass
    When method get
    Then status 200
    And match header Content-Type contains 'application/json'
    * def cliente = response
    * def customerId = cliente.id
    * def result = { customerId: customerId, cliente: cliente }
