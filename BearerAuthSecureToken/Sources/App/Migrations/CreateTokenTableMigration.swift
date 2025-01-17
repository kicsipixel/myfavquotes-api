import FluentKit

struct CreateTokenTableMigration: AsyncMigration {
    func prepare(on database:FluentKit.Database) async throws {
        try await database.schema("tokens")
            .id()
            .field("token_value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: FluentKit.Database) async throws {
        try await database.schema("tokens")
            .delete()
    }
}
