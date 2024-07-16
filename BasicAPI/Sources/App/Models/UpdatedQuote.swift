//
//  UpdatedQuote.swift
//
//
//  Created by Szabolcs Toth on 12.07.2024.
//

import Foundation
import Hummingbird

//  UpdatedQuote model for edit
struct UpdatedQuote: ResponseCodable {
    var quoteText: String?
    var author: String?
}
