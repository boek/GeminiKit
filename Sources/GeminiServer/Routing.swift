//
//  Handler.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import Core
import Foundation

public typealias GeminiHandler = @Sendable (GeminiRequest) async -> GeminiResponse?

func path(
    _ path: String,
    @HandlerBuilder _ handler: @escaping @Sendable () -> GeminiHandler
) -> GeminiHandler {
    return { request in
        guard request.path == path else { return nil }
        return await handler()(request)
    }
}

public func prefix(
    _ prefix: String,
    @HandlerBuilder _ handler: @escaping @Sendable () -> GeminiHandler
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

@resultBuilder
public struct HandlerBuilder {

    // Single handler passthrough
    public static func buildBlock(_ handler: @escaping GeminiHandler) -> GeminiHandler {
        handler
    }

    // Multiple handlers — try each in order, return first non-nil
    public static func buildBlock(_ handlers: GeminiHandler...) -> GeminiHandler {
        { request in
            for handler in handlers {
                if let response = await handler(request) { return response }
            }
            return nil
        }
    }

    // if / guard support
    public static func buildOptional(_ handler: GeminiHandler?) -> GeminiHandler {
        handler ?? { _ in nil }
    }

    // if/else support
    public static func buildEither(first handler: @escaping GeminiHandler) -> GeminiHandler { handler }
    public static func buildEither(second handler: @escaping GeminiHandler) -> GeminiHandler { handler }
}
