import FluentKit

struct CreateQuoteTableMigration: AsyncMigration {
  func prepare(on database: Database) async throws {
    return try await database.schema("quotes")
      .id()
      .field("quote_text", .string, .required)
      .field("author", .string, .required)
      .field("owner_id", .uuid, .required, .references("users", "id"))
      .unique(on: "quote_text")
      .create()
  }
  func revert(on database: Database) async throws {
    return try await database.schema("quotes").delete()
  }
}
