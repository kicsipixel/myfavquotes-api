import FluentKit
import Hummingbird
import HummingbirdAuth
import HummingbirdBcrypt
import HummingbirdFluent

struct UsersController<Context: RequestContext> {
    
    let fluent: Fluent
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .post(use: self.create)
    }
    
    // MARK: - Creates new user
    @Sendable func create(_ req: Request, context: Context) async throws -> EditedResponse<User.Public> {
        let user = try await req.decode(as: User.self, context: context)
        user.password = Bcrypt.hash(user.password)
        
        try await user.save(on: self.fluent.db())
        
        return .init(status: .created, response: User.Public(from: user))
    }
}