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
  
  init() {}
  
  init(id: UUID? = nil, quoteText: String, author: String) {
    self.id = id
    self.quoteText = quoteText
    self.author = author
  }
}

extension Quote: ResponseCodable, Codable {}
