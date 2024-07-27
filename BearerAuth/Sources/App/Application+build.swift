import FluentPostgresDriver
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent
import Logging

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "template")
        logger.logLevel = 
            arguments.logLevel ??
            environment.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ??
            .info
        return logger
    }()
    
    let router = Router(context: QuotesAuthRequestContext.self)
    // Add logging
    router.add(middleware: LogRequestsMiddleware(.info))
    
    // Add health endpoint
    router.get("/health") { _,_ -> HTTPResponse.Status in
        return .ok
    }
    
    let fluent = Fluent(logger: logger)
        
    // Database configuration
    let env = try await Environment.dotEnv()

    let postgreSQLConfig = SQLPostgresConfiguration(hostname: env.get("DATABASE_HOST") ?? "localhost",
                                                        port: env.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                                                        username: env.get("DATABASE_USERNAME") ?? "username",
                                                        password: env.get("DATABASE_PASSWORD") ?? "password",
                                                        database: env.get("DATABASE_NAME") ?? "hb-db",
                                                        tls: .prefer(try .init(configuration: .clientDefault)))
    
    fluent.databases.use(.postgres(configuration: postgreSQLConfig, sqlLogLevel: .warning), as: .psql)
    
    // Persist
    let persist = await FluentPersistDriver(fluent: fluent)
    
    // Database migration
    await fluent.migrations.add(CreateUserTableMigration())
    await fluent.migrations.add(CreateQuoteTableMigration())
    try await fluent.migrate()
    
    // Middlewares
    router.middlewares.add(BasicAuthenticator(fluent: fluent))
    router.middlewares.add(BearerAuthenticator(fluent: fluent, persist: persist))
    
    // Controllers
    QuotesController(fluent: fluent, persist: persist).addRoutes(to: router.group("api/v1/quotes"))
    UsersController(fluent: fluent, persist: persist).addRoutes(to: router.group("api/v1/users"))
    
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "template"
        ),
        logger: logger
    )
    
    app.addServices(fluent)
    app.addServices(persist)
    
    return app
}
