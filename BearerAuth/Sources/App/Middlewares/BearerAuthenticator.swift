import FluentKit
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent

struct BearerAuthenticator<Context: AuthRequestContext>: AuthenticatorMiddleware where Context.Identity == User  {
    let fluent: Fluent
    
    func authenticate(request: Request, context: Context) async throws -> User? {
        guard let bearer = request.headers.bearer else { return nil }

        let token = try await Token.query(on: self.fluent.db())
            .filter(\.$tokenValue == bearer.token)
            .first()

        guard let token = token else { return nil }
                
        let user = try await User.query(on: self.fluent.db())
            .filter(\.$id == token.$user.id)
            .first()
        
        guard let user = user else { return nil }
        
        return user
    }
}
