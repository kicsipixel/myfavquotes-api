import FluentKit
import Foundation
import Hummingbird
import HummingbirdFluent

struct QuotesController<Context: RequestContext> {
  
  let fluent: Fluent
  
  func addRoutes(to group:RouterGroup<Context>) {
    group
      .get(use: self.index)
      .get(":id", use: self.show)
      .post(use: self.create)
      .put(":id", use: self.update)
      .delete(":id", use: self.delete)
  }
  
    // MARK: - index
    /// Returns with all the quotes in the database
  @Sendable func index(_ request: Request, context: Context) async throws -> [Quote] {
    try await Quote.query(on: self.fluent.db()).all()
  }
  
    // MARK: - show
    /// Returns with the quote with {id}
  @Sendable func show(_ request: Request, context: Context) async throws -> Quote? {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let quote = try await Quote.find(id, on: fluent.db()) else {
      throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
    }
    
    return quote
  }
  
    // MARK: - create
    /// Creates new quote
  @Sendable func create(_ request: Request, context: Context) async throws -> Quote {
    let quote = try await request.decode(as: Quote.self, context: context)
    try await quote.save(on: fluent.db())
    return quote
  }
  
    // MARK: - edit
    /// Edits the quote with {id}
  @Sendable func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let quote = try await Quote.find(id, on: fluent.db()) else {
      throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
    }
    
    let updatedQuote = try await request.decode(as: UpdatedQuote.self, context: context)
    
    if let quoteText = updatedQuote.quoteText {
      quote.quoteText = quoteText
    }
    
    if let author = updatedQuote.author {
      quote.author = author
    }
    
    try await quote.save(on: fluent.db())
    
    return .ok
  }
  
    // MARK: - delete
    /// Deletes the quote with {id}
  @Sendable func delete(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let quote = try await Quote.find(id, on: fluent.db()) else {
      throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
    }
    
    try await quote.delete(on: fluent.db())
    return .ok
  }
}
