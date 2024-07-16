//
//  User.swift
//
//
//  Created by Szabolcs Toth on 12.07.2024.
//

import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth

final class User: Authenticatable, Model, @unchecked Sendable, ResponseCodable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "nickname")
    var nickname: String
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password")
    var password: String
    
    @Children(for: \.$owner)
    var quotes: [Quote]
        
    init() { }
    
    init(id: UUID? = nil, nickname: String, email: String, password: String) {
        self.id = id
        self.nickname = nickname
        self.email = email
        self.password = password
    }
    
    final class Public: ResponseCodable {
        let id: UUID?
        let nickname: String

        init(id: UUID?, nickname: String) {
            self.id = id
            self.nickname = nickname
        }

        init(from user: User) {
            self.id = user.id
            self.nickname = user.nickname
        }
    }
}
