import FluentKit
import Foundation
import Hummingbird

final class Token: Model, @unchecked Sendable, ResponseCodable {
    static let schema = "tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "token_value")
    var tokenValue: String

    @Parent(key: "user_id")
    var user: User

    init() {}

    init(id: UUID? = nil, tokenValue: String, userID: User.IDValue) {
        self.id = id
        self.tokenValue = tokenValue
        self.$user.id = userID
    }
}

extension Token {
    static func generate(for user: User) throws -> Token {
        let random = (1...8).map( {_ in Int.random(in: 0...999)} )
        let tokenString = String(describing: random).toBase64()
        return try Token(tokenValue: tokenString, userID: user.requireID())
    }
}