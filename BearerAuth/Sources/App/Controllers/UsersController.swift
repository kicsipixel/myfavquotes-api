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
            .post("token", use: self.token)
        group
            .add(middleware: IsAuthenticatedMiddleware(User.self))
            .post("login", use: self.login)
            .get("quotes", use: self.usersQuotes)
    }
    
    // MARK: - Create
    @Sendable func create(_ request: Request, context: Context) async throws -> EditedResponse<User.Public> {
        let user = try await request.decode(as: User.self, context: context)
        user.password = Bcrypt.hash(user.password)
        
        try await user.save(on: self.fluent.db())
        
        return .init(status: .created, response: User.Public(from: user))
    }
    
    // MARK: - Login
    @Sendable func login(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let user = try context.auth.require(User.self)
        let token = try Token.generate(for: user)
        
        // Token will expiry after 1 week
        try await persist.create(key: "\(token.tokenValue)", value: token, expires: .seconds(604800))
        
        return .ok
    }
    
    // MARK: - Token expiry
    @Sendable func token(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        guard let bearer = request.headers.bearer else { return .badRequest }
        
        let token = try await persist.get(key: "\(bearer.token)", as: Token.self)
        
        guard let token = token else {
            throw HTTPError(.unauthorized, message: "The token was expired, please login again.")
        }
        
        return .ok
    }
    
    // MARK: - Show quotes created by user
    /// Returns with the an array of quotes
    @Sendable func usersQuotes(_ request: Request, context: Context) async throws -> [Quote]? {
        let user = try context.auth.require(User.self)
        
        let quotes = try await Quote.query(on: self.fluent.db())
            .filter(\.$owner.$id == user.requireID())
            .all()
        
        return quotes
    }
}
