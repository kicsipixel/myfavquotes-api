//
//  Token.swift
//
//
//  Created by Szabolcs Tóth on 12.07.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth

final class Token: Model, @unchecked Sendable, ResponseCodable {
    static let schema = "tokens"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "token_value")
    var tokenValue: String
    
    @Parent(key: "user_id")
    var user: User
    
    init() { }
    
    init(id: UUID = UUID(), tokenValue: String, userID: User.IDValue) {
        self.id = id
        self.tokenValue = tokenValue
        self.$user.id = userID
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        // Keeping it simple for testing...
        let random = (1...2).map( {_ in Int.random(in: 0...9)} )
        let tokenString = String(describing: random).toBase64()
        return try Token(tokenValue: tokenString, userID: user.requireID())
    }
}



