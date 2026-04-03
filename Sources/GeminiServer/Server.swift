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

public struct Config {
    public var certPath: URL
    
    public init(certPath: URL) {
        self.certPath = certPath
    }
}

public struct Server {
    public var config: Config
    public var handler: GeminiHandler
    
    public init(config: Config, handler: @escaping GeminiHandler) {
        self.config = config
        self.handler = handler
    }
}
