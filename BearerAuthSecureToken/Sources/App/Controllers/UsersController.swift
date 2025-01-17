import Crypto
import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBcrypt
import HummingbirdFluent

struct UsersController {
    
    struct UserContext: ChildRequestContext {
        var coreContext: CoreRequestContextStorage
        var user: User
        
        init(context: QuotesAuthRequestContext) throws {
            self.coreContext = context.coreContext
            self.user = try context.requireIdentity()
        }
    }
    
    let fluent: Fluent
    
    func addRoutes(to group:RouterGroup<QuotesAuthRequestContext>) {
        group
            .post(use: self.create)
        group
            .add(middleware: IsAuthenticatedMiddleware())
            .group(context: UserContext.self)
            .post("login", use: self.login)
            .get("quotes", use: self.usersQuotes)
            .delete("logout", use: self.logout)
    }
    
    // MARK: - Creates a new user
    @Sendable func create(_ req: Request, context: QuotesAuthRequestContext) async throws -> EditedResponse<User.Public> {
        let user = try await req.decode(as: User.self, context: context)
        user.password = Bcrypt.hash(user.password)
        
        try await user.save(on: self.fluent.db())
        
        return .init(status: .created, response: User.Public(from: user))
    }
    
    // MARK: - Login user
    @Sendable func login(_ req: Request, context: UserContext) async throws -> Token {
        let user = context.user
        
        // Check if there is token already associated with the current user
        guard try await Token.query(on: self.fluent.db())
            .filter(\.$user.$id == user.requireID())
            .first() == nil else {
            throw HTTPError(.conflict, message: "You have already logged in.")
        }
        
        // Generate token and encrypt tokenValue
        let token = try Token.generate(for: user)
        
        let encryptedTokenValue = HashManager.hash(token.tokenValue)
        try await Token(id: token.id, tokenValue: encryptedTokenValue, userID: token.$user.id).save(on: self.fluent.db())
        
        return token
    }
    
    // MARK: - Logout user
    @Sendable func logout(_ req: Request, context: UserContext) async throws -> HTTPResponse.Status {
        guard let loggedInToken = try await Token.query(on: self.fluent.db())
            .filter(\.$user.$id == context.user.requireID())
            .first() else {
            throw HTTPError(.conflict, message: "You haven't logged in yet.")
        }
        
        try await loggedInToken.delete(on: self.fluent.db())
        return .ok
    }
    
    // MARK: - Show quotes created by user
    /// Returns with the an array of quotes
    @Sendable func usersQuotes(_ request: Request, context: UserContext) async throws -> [Quote]? {
        let quotes = try await Quote.query(on: self.fluent.db())
            .filter(\.$owner.$id == context.user.requireID())
            .all()
        
        return quotes
    }
}
