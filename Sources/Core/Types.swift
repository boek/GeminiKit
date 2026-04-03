//
//  Types.swift
//  GeminiServer
//
//  Created by Jeff Boek on 4/1/26.
//

import Foundation

public struct GeminiRequest: Sendable {
    private let url: URL

    // The path component, e.g. "/about"
    public var path: String { url.path }

    // The query string, e.g. user input from a prompt
    public var query: String? { url.query }

    // Convenience — was input provided?
    public var hasInput: Bool { url.query != nil }

    public init(url: URL) {
        self.url = url
    }
}

public enum GeminiStatus: Int, Sendable {
    case input              = 10
    case sensitiveInput     = 11
    case success            = 20
    case redirect           = 30
    case redirectPermanent  = 31
    case temporaryFailure   = 40
    case serverError        = 50
    case notFound           = 51
}

public struct GeminiResponse: Sendable {
    public var status: GeminiStatus
    public var meta: String
    public var body: Data?
    
    public init(status: GeminiStatus, meta: String, body: Data? = nil) {
        self.status = status
        self.meta = meta
        self.body = body
    }
}
