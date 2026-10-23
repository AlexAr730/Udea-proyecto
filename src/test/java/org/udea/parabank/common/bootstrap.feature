@ignore
Feature: Bootstrap de la suite

  # Se ejecuta UNA sola vez por corrida mediante karate.callSingle().
  # Responsabilidades:
  #   1. En local, dejar la base limpia (cleanDB).
  #   2. Autenticarse y obtener el customerId real.
  #   3. Garantizar dos cuentas operables para las transferencias.
  #   4. Devolver un objeto "ctx" que el resto de features consume.

  Scenario: Preparar el contexto compartido
    * url baseUrl
    * header Accept = 'application/json'
    * print 'bootstrap env =', env

    # 1. Reset: SOLO local (en publico borraria los datos de todos)
    * if (env == 'local') karate.call('classpath:org/udea/parabank/common/reset.feature')

    # 2. Login reutilizable (el resultado expone "response", no las variables def)
    #    Ruta absoluta de classpath: read() relativo se resuelve contra el
    #    feature llamador, no contra el directorio de bootstrap.
    * def login = call read('classpath:org/udea/parabank/common/login.feature')
    * def customerId = login.response.id
    * print 'bootstrap customerId =', customerId

    # 3. Cuentas que trae la base en este momento
    Given path 'customers', customerId, 'accounts'
    When method get
    Then status 200
    * def cuentas = response

    # 4. En local hace falta una segunda cuenta para transferir
    * if (env == 'local') karate.call('classpath:org/udea/parabank/common/crear-cuenta.feature', { customerId: customerId, fromAccountId: cuentas[0].id })

    # 5. Releer y elegir las dos cuentas con mayor saldo (sin LOAN)
    #    El call anterior deja el contexto HTTP sin headers: se declara de nuevo.
    * header Accept = 'application/json'
    Given path 'customers', customerId, 'accounts'
    When method get
    Then status 200
    * def operables = response.filter(function(c){ return c.type != 'LOAN' && c.balance > 0 })
    * def ordenadas = operables.sort(function(a,b){ return b.balance - a.balance })
    * assert ordenadas.length >= 2

    # Ojo: en Karate un objeto literal es JSON; para evaluar variables
    # hay que usar expresiones embebidas #(...)
    * def ctx = { env: '#(env)', customerId: '#(customerId)', fromAccountId: '#(ordenadas[0].id)', toAccountId: '#(ordenadas[1].id)', fromBalance: '#(ordenadas[0].balance)', accounts: '#(response)' }
    * print 'ctx =', ctx
    # El resultado de un call solo expone los built-ins: usamos "response"
    # como canal para devolver el contexto al llamador.
    * def response = ctx
