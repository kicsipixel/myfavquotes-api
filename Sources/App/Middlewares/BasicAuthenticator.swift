//
//  BasicAuthenticator.swift
//
//
//  Created by Szabolcs Toth on 12.07.2024.
//

import FluentKit
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent

struct BasicAuthenticator<Context: AuthRequestContext>: AuthenticatorMiddleware {
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
