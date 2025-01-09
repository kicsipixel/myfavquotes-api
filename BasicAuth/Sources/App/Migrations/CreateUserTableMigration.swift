import FluentKit

struct CreateUserTableMigration: AsyncMigration {
    func prepare(on database: FluentKit.Database) async throws {
        try await database.schema("users")
            .id()
            .field("nickname", .string, .required)
            .field("email", .string, .required)
            .field("password", .string, .required)
            .unique(on: "email")
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.schema("users")
            .delete()
    }
}