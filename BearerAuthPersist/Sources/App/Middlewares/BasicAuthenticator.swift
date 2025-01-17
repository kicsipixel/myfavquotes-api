import FluentKit
import Hummingbird
import HummingbirdAuth
import HummingbirdBcrypt
import HummingbirdFluent

struct BasicAuthenticator<Context: AuthRequestContext>: AuthenticatorMiddleware where Context.Identity == User {
  let fluent: Fluent
  
  func authenticate(request: Request, context: Context) async throws -> User? {
      // does request have basic authentication info in the "Authorization" header
    guard let basic = request.headers.basic else { return nil }
    
      // check if user exists in the database and then verify the entered password
      // against the one stored in the database. If it is correct then login in user
    let user = try await User.query(on: self.fluent.db())
      .filter(\.$email == basic.username)
      .first()
    guard let user = user else { return nil }
    guard Bcrypt.verify(basic.password, hash: user.password) else { return nil }
    
    return user
  }
}
