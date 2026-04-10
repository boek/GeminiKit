//
//  Handler.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import Core
import Foundation

protocol HandlerConvertable {
    var handler: Handler { get }
}

struct Handler {
    var handle: @Sendable (GeminiRequest) async -> GeminiResponse?

    func handle(request: GeminiRequest) async -> GeminiResponse? {
        await handle(request)
    }
}

extension Handler {
    static func input(_ prompt: String, next: @Sendable @escaping (String) -> Handler) -> Handler {
        return Handler { request in
            guard let response = request.query else {
                return .input(prompt)
            }

            return await next(response).handle(request: request)
        }
    }

    static func success(_ content: String) -> Handler {
        return Handler { _ in .success(content) }
    }

    static func path(_ path: String, next: Handler) -> Handler {
        return Handler { request in
            guard path == request.path else { return nil }
            return await next.handle(request)
        }
    }

    static func choose(_ handlers: [Handler]) -> Handler {
        return Handler { request in
            for handler in handlers {
                if let response = await handler.handle(request: request) {
                    return response
                }
            }

            return nil
        }
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

