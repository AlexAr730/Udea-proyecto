function fn() {
    // -----------------------------------------------------------------------
    // Entorno activo. Se elige desde Maven:
    //   mvn test                          -> local   (por defecto)
    //   mvn test -Dkarate.env=publico     -> demo del profesor
    // -----------------------------------------------------------------------
    var env = karate.env || 'local';

    var config = {
        env: env,
        user: 'john',
        pass: 'demo',
        customerId: 12212
    };

    if (env === 'publico') {
        // Instancia compartida por todos los equipos: sin reset y más lenta.
        config.baseUrl = 'https://parabank.parasoft.com/parabank/services/bank';
        config.appUrl = 'https://parabank.parasoft.com/parabank';
        config.connectTimeout = 15000;
        config.readTimeout = 45000;
    } else {
        // ParaBank en Docker (ver docker-compose.yml).
        config.baseUrl = 'http://localhost:8080/parabank/services/bank';
        config.appUrl = 'http://localhost:8080/parabank';
        config.connectTimeout = 10000;
        config.readTimeout = 30000;
    }

    karate.configure('connectTimeout', config.connectTimeout);
    karate.configure('readTimeout', config.readTimeout);

    // Faker para generar datos únicos en las pruebas que lo necesiten.
    var Faker = Java.type('com.github.javafaker.Faker');
    config.faker = new Faker();

    // -----------------------------------------------------------------------
    // Fase 2: contexto compartido (reset de BD + login + cuentas de prueba).
    // Se activa cuando exista common/bootstrap.feature.
    //
    // config.ctx = karate.callSingle(
    //     'classpath:org/udea/parabank/common/bootstrap.feature', config);
    // -----------------------------------------------------------------------

    return config;
}
