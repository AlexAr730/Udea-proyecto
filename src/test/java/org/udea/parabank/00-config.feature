@config
Feature: Configuracion del entorno de pruebas

  # Este feature NO llama a ParaBank. Solo comprueba que karate-config.js

  Scenario: El baseUrl corresponde al entorno activo
    * print 'env     =', env
    * print 'baseUrl =', baseUrl
    * print 'appUrl  =', appUrl
    * def hostEsperado = env == 'publico' ? 'parabank.parasoft.com' : 'localhost:8080'
    * match baseUrl contains hostEsperado
    * assert baseUrl.endsWith('/parabank/services/bank')
    * assert appUrl.endsWith('/parabank')

  Scenario: Los timeouts son suficientes para la aplicacion
    * match connectTimeout == '#number'
    * match readTimeout == '#number'
    * assert readTimeout >= 30000

  Scenario: Credenciales y datos de prueba definidos
    * match user == 'john'
    * match pass == 'demo'
    * match customerId == 12212

  Scenario: Faker esta disponible como instancia
    * def nombre = faker.name().firstName()
    * match nombre == '#string'
