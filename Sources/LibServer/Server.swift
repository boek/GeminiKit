//
//  Server.swift
//  GeminiServer
//
//  Created by Jeff Boek on 4/1/26.
//

import Core

import Foundation
import NIOCore

public struct Config {
    public var certificatePath: URL
    public var privateKeyPath: URL
    public var host: String
    public var port: Int
    public var numberOfThreads: Int

    public init(
        certificatePath: URL,
        privateKeyPath: URL,
        host: String = "0.0.0.0",
        port: Int = 1965,
        numberOfThreads: Int = System.coreCount
    ) {
        self.certificatePath = certificatePath
        self.privateKeyPath = privateKeyPath
        self.host = host
        self.port = port
        self.numberOfThreads = numberOfThreads
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
