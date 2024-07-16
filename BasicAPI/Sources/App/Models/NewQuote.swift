//
//  NewQuote.swift
//  
//
//  Created by Szabolcs Toth on 12.07.2024.
//

import Foundation
import Hummingbird

//  NewQuote model for create
struct NewQuote: ResponseCodable {
    var quoteText: String
    var author: String
}
