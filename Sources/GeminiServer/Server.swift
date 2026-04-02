//
//  Server.swift
//  GeminiServer
//
//  Created by Jeff Boek on 4/1/26.
//

import Core
import LibNetworking

import Foundation
import NIOCore

public struct GeminiHandler: Sendable {
    var handle: @Sendable (GeminiRequest) async throws -> GeminiResponse
    
    public init(handle: @Sendable @escaping (GeminiRequest) async throws -> GeminiResponse) {
        self.handle = handle
    }
    
    public func callAsFunction(_ request: GeminiRequest) async throws -> GeminiResponse {
        try await handle(request)
    }
}

public struct GeminiServer {
    var start: (Config, GeminiHandler) async throws -> Void
    
    public func start(config: Config, handler: GeminiHandler) async throws {
        try await self.start(config, handler)
    }
}

public struct Certificate {
    public var key: Data
    public var cert: Data
    
    public init(key: Data, cert: Data) {
        self.key = key
        self.cert = cert
    }
}

public extension GeminiServer {
    struct Config {
        public var certificate: Certificate
        
        public init(certificate: Certificate) {
            self.certificate = certificate
        }
    }
}
