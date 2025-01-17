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

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "BearerAuthSecureToken")
        logger.logLevel =
        arguments.logLevel ??
        environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .debug
        return logger
    }()
    
    let fluent = Fluent(logger: logger)
    let router = buildRouter(fluent: fluent)
    
    let env = try await Environment.dotEnv()
    
    // Database configuration - env.get("DATABASE_HOST") ??
    let postgreSQLConfig = SQLPostgresConfiguration(hostname: "localhost",
                                                    port: env.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                                                    username: env.get("DATABASE_USERNAME") ?? "username",
                                                    password: env.get("DATABASE_PASSWORD") ?? "password",
                                                    database: env.get("DATABASE_NAME") ?? "hb-db",
                                                    tls: .prefer(try .init(configuration: .clientDefault)))
    fluent.databases.use(.postgres(configuration: postgreSQLConfig, sqlLogLevel: .warning), as: .psql)
    
    // Database migration
    await fluent.migrations.add(CreateUserTableMigration())
    await fluent.migrations.add(CreateQuoteTableMigration())
    await fluent.migrations.add(CreateTokenTableMigration())
    try await fluent.migrate()
    
    // Controllers
    QuotesController(fluent: fluent).addRoutes(to: router.group("api/v1/quotes"))
    UsersController(fluent: fluent).addRoutes(to: router.group("api/v1/users"))
    
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "BearerAuthSecureToken"
        ),
        logger: logger
    )
    
    app.addServices(fluent)
    
    return app
}

/// Build router
func buildRouter(fluent: Fluent) -> Router<QuotesAuthRequestContext> {
    let router = Router(context: QuotesAuthRequestContext.self)
    
    // Add middlewares
    router.addMiddleware {
        LogRequestsMiddleware(.debug)
        BasicAuthenticator(fluent: fluent)
        BearerAuthenticator(fluent: fluent)
    }
    
    // Add default endpoint
    router.get("/health") { _, _ -> HTTPResponse.Status in
            .ok
    }
    
    return router
}
