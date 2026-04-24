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

    static func sensitiveInput(_ prompt: String, next: @Sendable @escaping (String) -> Handler) -> Handler {
        return Handler { request in
            guard let response = request.query else {
                return .sensitiveInput(prompt)
            }

            return await next(response).handle(request: request)
        }
    }

    static func success(_ content: String) -> Handler {
        return Handler { _ in .success(content) }
    }

    static func match(_ path: String, next: @Sendable @escaping (Parameters) -> Handler) -> Handler {
        return Handler { request in
            let templateParts = path.split(separator: "/", omittingEmptySubsequences: false)
            let actualParts = request.path.split(separator: "/", omittingEmptySubsequences: false)

            guard templateParts.count == actualParts.count else { return nil }

            let matches = zip(templateParts, actualParts).allSatisfy { template, actual in
                template.hasPrefix(":") || template == actual
            }

            guard matches else { return nil }

            let params = Parameters(path: path, compared: request.path)
            return await next(params).handle(request: request)
        }
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

    // 40–44 Temporary Failures
    static func failure(_ reason: String = "Temporary failure") -> GeminiResponse {
        GeminiResponse(status: .temporaryFailure, meta: reason)
    }

    static func serverUnavailable(_ reason: String = "Server unavailable") -> GeminiResponse {
        GeminiResponse(status: .serverUnavailable, meta: reason)
    }

    static func slowDown(seconds: Int) -> GeminiResponse {
        GeminiResponse(status: .slowDown, meta: "\(seconds)")
    }

    // 50–59 Permanent Failures
    static func serverError(_ reason: String = "Server error") -> GeminiResponse {
        GeminiResponse(status: .serverError, meta: reason)
    }

    static func notFound(_ reason: String = "Not found") -> GeminiResponse {
        GeminiResponse(status: .notFound, meta: reason)
    }

    static func gone(_ reason: String = "Gone") -> GeminiResponse {
        GeminiResponse(status: .gone, meta: reason)
    }

    static func badRequest(_ reason: String = "Bad request") -> GeminiResponse {
        GeminiResponse(status: .badRequest, meta: reason)
    }
}

