//
//  UsersController.swift
//
//
//  Created by Szabolcs Toth on 12.07.2024.
//

import FluentKit
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent

struct UsersController<Context: RequestContext> {
    
    let fluent: Fluent
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .get(use: self.index)
            .post(use: self.create)
    }
    
    // MARK: - Create
    @Sendable func create(_ req: Request, context: Context) async throws -> EditedResponse<User.Public> {
        let user = try await req.decode(as: User.self, context: context)
        user.password = Bcrypt.hash(user.password)
        
        try await user.save(on: self.fluent.db())
        
        return .init(status: .created, response: User.Public(from: user))
    }
    
    // MARK: - List
    @Sendable func index(_ request: Request, context: Context) async throws -> [User] {
        return try await User.query(on: self.fluent.db()).all()
    }
}
