import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent

struct BearerAuthenticator<Context: AuthRequestContext>: AuthenticatorMiddleware where Context.Identity == User  {
    let fluent: Fluent
    let persist: FluentPersistDriver
    
    func authenticate(request: Request, context: Context) async throws -> User? {
        guard let bearer = request.headers.bearer else { return nil }
        
        let token = try await persist.get(key: "\(bearer.token)", as: Token.self)
        
        guard let token = token else {
            throw HTTPError(.unauthorized, message: "The token hasn't been found. It might have been already expired/deleted or your token is not valid.")
        }
        
        let user = try await User.query(on: self.fluent.db())
            .filter(\.$id == token.$user.id)
            .first()
        
        guard let user = user else { return nil }
        
        return user
    }
}
