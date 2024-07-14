//
//  CreateTokenTableMigration.swift
//
//
//  Created by Szabolcs Tóth on 12.07.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentKit

struct CreateTokenTableMigration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tokens")
            .id()
            .field("token_value", .string, .required)
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("tokens")
            .delete()
    }
}
