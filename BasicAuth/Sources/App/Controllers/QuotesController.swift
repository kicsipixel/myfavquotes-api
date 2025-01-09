import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent

struct QuotesController {
  
  struct QuoteContext: ChildRequestContext {
    var coreContext: CoreRequestContextStorage
    var user: User
    
    init(context: QuotesAuthRequestContext) throws {
      self.coreContext = context.coreContext
      self.user = try context.requireIdentity()
    }
  }
  
  let fluent: Fluent
  
  func addRoutes(to group:RouterGroup<QuotesAuthRequestContext>) {
    group
      .get(use: self.index)
      .get(":id", use: self.show)
      .add(middleware: IsAuthenticatedMiddleware())
      .group(context: QuoteContext.self)
      .post(use: self.create)
      .put(":id", use: self.update)
      .delete(":id", use: self.delete)
  }
  
    // MARK: - index
    /// Returns with all the quotes in the database
  @Sendable func index(_ request: Request, context: QuotesAuthRequestContext) async throws -> [Quote] {
    try await Quote.query(on: self.fluent.db()).all()
  }
  
    // MARK: - show
    /// Returns with the quote with {id}
  @Sendable func show(_ request: Request, context: QuotesAuthRequestContext) async throws -> Quote? {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let quote = try await Quote.find(id, on: fluent.db()) else {
      throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
    }
    
    return quote
  }
  
    // MARK: - create
    /// Create new quote
  @Sendable func create(_ request: Request, context: QuoteContext) async throws -> Quote {
    let userInput = try await request.decode(as: NewQuote.self, context: context)
    let quote = try Quote(quoteText: userInput.quoteText, author: userInput.author, ownerID: context.user.requireID())
    
    try await quote.save(on: fluent.db())
    return quote
  }
  
    // MARK: - edit
    /// Edits the quote with {id}
  @Sendable func update(_ request: Request, context: QuoteContext) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let quote = try await Quote.find(id, on: fluent.db()) else {
      throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
    }
    
    guard context.user.id == quote.$owner.id else {
      throw HTTPError(.unauthorized, message: "You cannot edit someone else's quote.")
    }
    
    let userInput = try await request.decode(as: UpdatedQuote.self, context: context)
    
      // Check if the user submitted any changes, ignore if it is nil
    if let quoteText = userInput.quoteText {
      quote.quoteText = quoteText
    }
    
    if let author = userInput.author {
      quote.author = author
    }
    
    try await quote.save(on: fluent.db())
    return .ok
  }
  
    // MARK: - delete
    /// Deletes the quote with {id}
  @Sendable func delete(_ request: Request, context: QuoteContext) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: UUID.self)
    guard let quote = try await Quote.find(id, on: fluent.db()) else {
      throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
    }
    
    guard context.user.id == quote.$owner.id else {
      throw HTTPError(.unauthorized, message: "You cannot delete someone else's quote.")
    }
    
    try await quote.delete(on: fluent.db())
    return .ok
  }
}
