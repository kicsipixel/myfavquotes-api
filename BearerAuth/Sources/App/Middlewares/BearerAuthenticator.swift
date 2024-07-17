//
//  BearerAuthenticator.swift
//  
//
//  Created by Szabolcs Tóth on 14.07.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentKit
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent

struct BearerAuthenticator<Context: AuthRequestContext>: AuthenticatorMiddleware {
    let fluent: Fluent
    let persist: FluentPersistDriver
    
    func authenticate(request: Request, context: Context) async throws -> User? {
        guard let bearer = request.headers.bearer else { return nil }
        
        let token = try await persist.get(key: "\(bearer.token)", as: Token.self)
        
        guard let token = token else {
            throw HTTPError(.unauthorized, message: "The token was expired, please login again.")
        }
                
        let user = try await User.query(on: self.fluent.db())
            .filter(\.$id == token.$user.id)
            .first()
        
        guard let user = user else { return nil }
        
        return user
    }
}
