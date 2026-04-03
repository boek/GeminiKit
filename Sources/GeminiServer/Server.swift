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
