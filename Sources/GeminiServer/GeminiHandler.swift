//
//  GeminiHandler.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//
import Foundation

import Core

public struct GeminiHandler: Sendable {
    var handle: @Sendable (GeminiRequest) async throws -> GeminiResponse?
    
    public init(handle: @Sendable @escaping (GeminiRequest) async throws -> GeminiResponse?) {
        self.handle = handle
    }
    
    public func callAsFunction(_ request: GeminiRequest) async throws -> GeminiResponse? {
        try await handle(request)
    }
}

extension GeminiHandler {
    
    public static func path(_ path: String, _ handler: GeminiHandler) -> GeminiHandler {
        GeminiHandler { request in
            guard request.url.path.hasPrefix(path) else { return nil }
            let url = URL(string: String(request.url.path.trimmingPrefix(path))) ?? URL(string: "/")!
            
            let newRequest = GeminiRequest(url: url)
            return try await handler.handle(newRequest)
        }
    }
    
    public static func success(_ body: String) -> GeminiHandler {
        GeminiHandler { _ in GeminiResponse(status: .success, meta: "text/gemini", body: body.data(using: .utf8)!) }
    }
    
    public static func choose(routes: [GeminiHandler]) -> GeminiHandler {
        GeminiHandler { request in
            for route in routes {
                guard let response = try await route.handler.handle(request) else { continue }
                return response
            }
            
            return nil
        }
    }
}
