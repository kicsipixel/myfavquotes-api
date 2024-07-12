//
//  Quote.swift
//
//
//  Created by Szabolcs Tóth on 05.07.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentKit
import Foundation
import Hummingbird

final class Quote: Model, @unchecked Sendable {
    static let schema = "quotes"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "quote_text")
    var quoteText: String
    
    @Field(key: "author")
    var author: String
    
    @Parent(key: "owner_id")
    var owner: User
    
    init() {}
    
    init(id: UUID? = nil, quoteText: String, author: String, ownerID: User.IDValue) {
        self.id = id
        self.quoteText = quoteText
        self.author = author
        self.$owner.id = ownerID
    }
}

extension Quote: ResponseCodable, Codable {}
