//
//  QuotesAuthRequestContext.swift
//  
//
//  Created by Szabolcs Toth on 12.07.2024.
//

import Hummingbird
import HummingbirdAuth

struct QuotesAuthRequestContext: AuthRequestContext, RequestContext {
    var coreContext: CoreRequestContextStorage
    var auth: LoginCache

    init(source: Source) {
        self.coreContext = .init(source: source)
        self.auth = .init()
    }
}
