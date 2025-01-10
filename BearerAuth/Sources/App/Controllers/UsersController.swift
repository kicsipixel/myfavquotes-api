import FluentKit
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
        let token = try Token.generate(for: user)
        try await token.save(on: self.fluent.db())
        
        return token
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
