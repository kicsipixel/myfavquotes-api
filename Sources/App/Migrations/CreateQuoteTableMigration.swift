//
//  CreateQuoteTableMigration.swift
//
//
//  Created by Szabolcs Tóth on 05.07.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

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
