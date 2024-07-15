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

struct UsersController<Context: AuthRequestContext & RequestContext> {
    
    let fluent: Fluent
    let persist: FluentPersistDriver
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .post(use: self.create)
            .add(middleware: IsAuthenticatedMiddleware(User.self))
            .post("login", use: self.login)
    }
    
    // MARK: - Create
    @Sendable func create(_ req: Request, context: Context) async throws -> EditedResponse<User.Public> {
        let user = try await req.decode(as: User.self, context: context)
        user.password = Bcrypt.hash(user.password)
        
        try await user.save(on: self.fluent.db())
        
        return .init(status: .created, response: User.Public(from: user))
    }
    
    // MARK: - Login
    @Sendable func login(_ req: Request, context: Context) async throws -> Token {
        let user = try context.auth.require(User.self)
        let token = try Token.generate(for: user)
        
        try await persist.create(key: "\(token.tokenValue)", value: token, expires: .seconds(3600))
        
        return token
    }
}
