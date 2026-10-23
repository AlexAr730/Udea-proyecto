@contexto
Feature: Contexto compartido de pruebas

  # Verifica que bootstrap.feature (ejecutado una sola vez con callSingle)
  # entregue cuentas utilizables. Sirve como diagnostico cuando otro feature
  # falla por datos y no por logica.

  Background:
    * def ctx = karate.callSingle('classpath:org/udea/parabank/common/bootstrap.feature').response

  @smoke
  Scenario: El bootstrap entrega dos cuentas operables
    * match ctx.customerId == customerId
    * match ctx.fromAccountId == '#number'
    * match ctx.toAccountId == '#number'
    * assert ctx.fromAccountId != ctx.toAccountId
    * match ctx.accounts == '#array'
    * print 'cuentas de trabajo:', ctx.fromAccountId, '->', ctx.toAccountId
