//
//  QuotesController.swift
//
//
//  Created by Szabolcs Tóth on 11.07.2024.
//  Copyright © 2024 Szabolcs Tóth. All rights reserved.
//

import FluentKit
import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdFluent

struct QuotesController<Context: AuthRequestContext & RequestContext> {
    
    let fluent: Fluent
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .get(use: self.index)
            .get(":id", use: self.show)
        group
            .add(middleware: BearerAuthenticator(fluent: fluent))
            .post(use: self.create)
            .put(":id", use: self.update)
            .delete(":id", use: self.delete)
    }
    
    // MARK: - index
    /// Returns with all the quotes in the database
    @Sendable func index(_ request: Request, context: Context) async throws -> [Quote] {
        return try await Quote.query(on: self.fluent.db()).all()
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
    /// Create new quote
    @Sendable func create(_ request: Request, context: Context) async throws -> Quote {
        let user = try context.auth.require(User.self)
        let userInput = try await request.decode(as: NewQuote.self, context: context)
        let quote = try Quote(quoteText: userInput.quoteText, author: userInput.author, ownerID: user.requireID())
        try await quote.save(on: fluent.db())
        return quote
    }
    
    // MARK: - edit
    /// Edit the quote with {id}
    @Sendable func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let user = try context.auth.require(User.self)
        let id = try context.parameters.require("id", as: UUID.self)
        guard let originalQuote = try await Quote.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
        }
        
        let userInput = try await request.decode(as: UpdatedQuote.self, context: context)
        
        // Check if the user submitted any changes, ignore if it is nil
        if let quoteText = userInput.quoteText {
            originalQuote.quoteText = quoteText
        }
        
        if let author = userInput.author {
            originalQuote.author = author
        }
        
        let quote = try Quote(quoteText: originalQuote.quoteText, author: originalQuote.author, ownerID: user.requireID())
        
        try await quote.save(on: fluent.db())
        
        return .ok
    }
    
    // MARK: - delete
    /// Delete the quote with {id}
    @Sendable func delete(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let user = try context.auth.require(User.self)
        let id = try context.parameters.require("id", as: UUID.self)
        guard let quote = try await Quote.find(id, on: fluent.db()) else {
            throw HTTPError(.notFound, message: "This quote is not in the database. Try different one.")
        }
        
        guard user.id == quote.$owner.id else {
            throw HTTPError(.unauthorized, message: "You cannot delete someone else's quote.")
        }
        
        try await quote.delete(on: fluent.db())
        return .ok
    }
}
