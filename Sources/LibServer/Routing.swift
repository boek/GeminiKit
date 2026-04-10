//
//  Handler.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import Core
import Foundation

public typealias GeminiHandler = @Sendable (GeminiRequest) async -> GeminiResponse?

enum Handler {
    
}

func path(
    _ path: String,
    _ handler: @escaping @Sendable () -> GeminiHandler
) -> GeminiHandler {
    return { request in
        guard request.path == path else { return nil }
        return await handler()(request)
    }
}

public func prefix(
    _ prefix: String,
    _ handler: @escaping @Sendable () -> GeminiHandler
) -> GeminiHandler {
    return { request in
        guard request.path.hasPrefix(prefix) else { return nil }
        return await handler()(request)
    }
}

public extension GeminiResponse {
    // 20 Success
    static func success(_ body: String, mimeType: String = "text/gemini; charset=utf-8") -> GeminiResponse {
        GeminiResponse(status: .success, meta: mimeType, body: Data(body.utf8))
    }

    // 10/11 Input
    static func input(_ prompt: String) -> GeminiResponse {
        GeminiResponse(status: .input, meta: prompt)
    }

    static func sensitiveInput(_ prompt: String) -> GeminiResponse {
        GeminiResponse(status: .sensitiveInput, meta: prompt)
    }

    // 30/31 Redirect
    static func redirect(to url: String) -> GeminiResponse {
        GeminiResponse(status: .redirect, meta: url)
    }

    static func permanentRedirect(to url: String) -> GeminiResponse {
        GeminiResponse(status: .redirectPermanent, meta: url)
    }

    // 40–59 Errors
    static func notFound(_ reason: String = "Not found") -> GeminiResponse {
        GeminiResponse(status: .notFound, meta: reason)
    }

    static func failure(_ reason: String) -> GeminiResponse {
        GeminiResponse(status: .temporaryFailure, meta: reason)
    }

    static func badRequest(_ reason: String = "Bad request") -> GeminiResponse {
        GeminiResponse(status: .serverError, meta: reason)
    }
}

