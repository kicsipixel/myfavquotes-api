# MyFavQuotes
## All the favourite quotes in one place

Our API application collects quotes and users can like it. Everyone can see the quotes, but to “like” it or create, update, delete, users must be authenticated.

 A simple JSON response will look like this:
 
 ```json
[
   {
      "quoteText":"I agree with Dante, that the hottest places in hell are reserved for those who in a period of moral crisis maintain their neutrality. There comes a time when silence becomes betrayal.",
      "author":"Martin Luther King, Jr."
   },
   {
      "quoteText":"Don't count the days. Make the days count.",
      "author":"Muhammad Ali "
   },
   {
      "quoteText":"Learn the rules like a pro, so you can break them like an artist.",
      "author":"Pablo Picasso"
   },
   {
      "quoteText":"Try to be a rainbow in someone's cloud.",
      "author":"Maya Angelou "
   }
]
 ```
 
## Clone and configure the Hummingbird template
 
 ```bash
 $ git clone https://github.com/hummingbird-project/template 
 $ cd template
 $ ./configure ../myfavquotes-api
 ```
 

## Add PostgreSQL dependencies

Our server will use PostgreSQL database to store all data, so we need to add two database dependencies:
- [Fluent driver for PostgreSQL database](https://github.com/vapor/fluent-postgres-driver)
- [Hummingbird Fluent](https://github.com/hummingbird-project/hummingbird-fluent)

to our manifest file. This will allow the server to communicate to the database.

The updated `Package.swift` file will look like this:

```swift
import PackageDescription

let package = Package(
    name: "template",
    platforms: [.macOS(.v14), .iOS(.v17), .tvOS(.v17)],
    products: [
        .executable(name: "App", targets: ["App"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-rc.2"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.9.2"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-fluent.git", from: "2.0.0-beta.1")
    ],
    targets: [
        .executableTarget(name: "App",
                          dependencies: [
                            .product(name: "ArgumentParser", package: "swift-argument-parser"),
                            .product(name: "Hummingbird", package: "hummingbird"),
                            .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                            .product(name: "HummingbirdFluent", package: "hummingbird-fluent")
                          ],
                          path: "Sources/App"
                         ),
        .testTarget(name: "AppTests",
                    dependencies: [
                        .byName(name: "App"),
                        .product(name: "HummingbirdTesting", package: "hummingbird")
                    ],
                    path: "Tests/AppTests"
                   )
    ]
)
```


## Add `Quote` model
 
Create `Models` folder under `Sources/App` and add `Quote.swift`:

```swift
import FluentKit
import Foundation
import Hummingbird

final class Quote: Model, @unchecked Sendable {
    static let schema = "quotes"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "quote_text")
    var quoteText: String
    
    @Field(key: "author")
    var author: String
    
    init() {}
    
    init(id: UUID? = nil, quoteText: String, author: String) {
        self.id = id
        self.quoteText = quoteText
        self.author = author
    }
}

extension Quote: ResponseCodable, Codable {}
```
 
 ##  Create a database migration file
To represent our `Quote` model in database, we need to create a migration file. For better organisation it is recommended to create `Migrations` folder under `Sources/App`.

The `CreateQuoteTableMigration.swift` is

```swift
import FluentKit

struct CreateQuoteTableMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        return try await database.schema("quotes")
            .id()
            .field("quote_text", .string, .required)
            .field("author", .string, .required)
            .unique(on: "quote_text")
            .create()
    }
    
    func revert(on database: Database) async throws {
        return try await database.schema("quotes").delete()
    }
}
```

## Add migration to `Application+build.swift`

In our `Application+build.swift` file import the following additional libraries:

```swift
import FluentPostgresDriver
import HummingbirdFluent
```

For security reason we don’t want to include the database credentials into our source code and replicate to a public repository.

That’s why we will use `environment variables` to set the database credentials.

Create `.env` file:

```
$ touch .env
```

Copy the following into `.env`:

```
DATABASE_HOST=db
DATABASE_NAME=myfav_quotes
DATABASE_USERNAME=hb_usernam3
DATABASE_PASSWORD=s3cr3t
PGDATA=/var/lib/postgresql/data/pgdata
POSTGRES_USER=hb_usernam3
POSTGRES_PASSWORD=s3cr3t
POSTGRES_DB=myfav_quotes
POSTGRES_HOST=localhost
# pgAdmin
PGADMIN_DEFAULT_EMAIL=pgAdmin@mail.com
PGADMIN_DEFAULT_PASSWORD=pgAdmin_secr3t
```
Add the following to able to read `.env` file:

```
 let env = try await Environment.dotEnv()
```

Add `Fluent`:

```
let fluent = Fluent(logger: logger)
```

Create configuration:

```swift
let postgreSQLConfig = SQLPostgresConfiguration(hostname: env.get("DATABASE_HOST") ?? "localhost",
                                                    port: env.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
                                                    username: env.get("DATABASE_USERNAME") ?? "username",
                                                    password: env.get("DATABASE_PASSWORD") ?? "password",
                                                    database: env.get("DATABASE_NAME") ?? "hb-db",
                                                    tls: .prefer(try .init(configuration: .clientDefault)))
```

Setup your database:

```
fluent.databases.use(.postgres(configuration: postgreSQLConfig, sqlLogLevel: .warning), as: .psql)
```

Add database migration, we have created:
```
await fluent.migrations.add(CreateParkTableMigration())
```

Execute migration:

```
try await fluent.migrate()
```

Add fluent to appServices at the end:

```
app.addServices(fluent)
```

## Check `CreateQuoteTableMigration`

Create `docker-compose.yml` to run PostgreSQL database without installing it on our own machine.

```yaml
services:
  app:
    image: myfav_quotes-api:latest
    build:
      context: .
    env_file:
      - .env
    depends_on:
      - db
    ports:
      - '8080:8080'
    command: ["--hostname", "0.0.0.0", "--port", "8080"]
  db:
    image: postgres:16-alpine
    volumes:
      - db_data:/var/lib/postgresql/data/pgdata
    env_file:
      - .env
    ports:
      - 5432:5432
  pgadmin:
    image: dpage/pgadmin4
    restart: always
    ports:
      - "8888:80"
    env_file:
      - .env
    volumes:
      - pgadmin-data:/var/lib/pgadmin
      
volumes:
  db_data:
  pgadmin-data:
```

As we don’t have any controller yet, the best way to check if the migration works to see if the table with the required scheme are created or not. 

If you missed, you can read [my previous article](https://medium.com/@kicsipixel/install-pgadmin-with-postgresql-database-using-docker-ded3e2dfbe3b) how to setup pgAdmin.

__Build and start the containers:__

```
$ docker compose build
$ docker compose up app
$ docker compose up pgadmin
```

![Screentshot here....](~/Desktop/Screenshot 2024-07-05 at 23.19.41.png)

## Create `QuotesController`
The Controller receives an input from the users, then processes the user's data with the help of `Model` and passes the results back.

Our server will be accessible on the following routes, using different HTTP methods.
- __GET__- `http://127.0.0.1:8080/api/v1/quotes`: Lists all the quotes in the database
- __GET__ - `http://127.0.0.1:8080/api/v1/quotes/:{id}`: Shows a single quote with given id
- __POST__ - `http://127.0.0.1:8080/api/v1/quotes`: Creates a new quote
- __PUT__ - `http://127.0.0.1:8080/api/v1/quotes/:{id}`: Updates the quote with the given id
- __DELETE__ - `http://127.0.0.1:8080/api/v1/quotes/:{id}`: Removes the quote with id from database

Add `QuotesController.swift` to a new `Controllers` folder under `Source/App`.

```swift
import FluentKit
import Foundation
import Hummingbird
import HummingbirdFluent

struct QuotesController<Context: RequestContext> {
    
    let fluent: Fluent
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .get(use: self.index)
            .get(":id", use: self.show)
            .post(use: self.create)
            .put(":id", use: self.update)
            .delete(":id", use: self.delete)
    }
    
    // MARK: - index
    /// Returns with all the quotes in the database
    @Sendable func index(_ request: Request, context: Context) async throws -> [Quote] {
        try await Quote.query(on: self.fluent.db()).all()
    }
    
    // MARK: - show
    /// Returns with the quote with {id}
    @Sendable func show(_ request: Request, context: Context) async throws -> Quote? {
        let id = try context.parameters.require("id", as: UUID.self)
        guard let quote = try await Quote.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
        }
        
        return quote
    }
    
    // MARK: - create
    /// Create new quote
    @Sendable func create(_ request: Request, context: Context) async throws -> Quote {
        let quote = try await request.decode(as: Quote.self, context: context)
        try await quote.save(on: fluent.db())
        return quote
    }
    
    // MARK: - edit
    /// Edit the quote with {id}
    @Sendable func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: UUID.self)
        guard let quote = try await Quote.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
        }
        
        let updatedQuote = try await request.decode(as: Quote.self, context: context)
        
        quote.quoteText = updatedQuote.quoteText
        quote.author = updatedQuote.author
        
        try await quote.save(on: fluent.db())
        
        return .ok
    }
    
    // MARK: - delete
    /// Delete the quote with {id}
    @Sendable func delete(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: UUID.self)
        guard let quote = try await Quote.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
        }
        
        try await quote.delete(on: fluent.db())
        return .ok
    }
}
```





