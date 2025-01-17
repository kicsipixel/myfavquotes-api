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
    let persist: FluentPersistDriver
    
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
    @Sendable func create(_ request: Request, context: QuotesAuthRequestContext) async throws -> EditedResponse<User.Public> {
        let user = try await request.decode(as: User.self, context: context)
        user.password = Bcrypt.hash(user.password)
        
        try await user.save(on: self.fluent.db())
        
        return .init(status: .created, response: User.Public(from: user))
    }
    
    // MARK: - Login user
    @Sendable func login(_ request: Request, context: UserContext) async throws -> Token {
        let user = context.user
        let token = try Token.generate(for: user)
        
        try await persist.create(key: "\(token.tokenValue)", value: token, expires: .seconds(3600))
        
        return token
    }
    
    // MARK: - Logout user
    @Sendable func logout(_ request: Request, context: UserContext) async throws -> HTTPResponse.Status {
        guard let bearer = request.headers.bearer else {
            throw HTTPError(.badRequest)
        }
                
        try await persist.remove(key: "\(bearer.token)")
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
