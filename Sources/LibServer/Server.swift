//
//  Server.swift
//  GeminiServer
//
//  Created by Jeff Boek on 4/1/26.
//

import Core

import Foundation
import NIOCore

public struct Config: Sendable {
    public var certificatePath: URL
    public var privateKeyPath: URL
    public var host: String
    public var port: Int
    public var numberOfThreads: Int
    public var requestTimeout: Duration

    public init(
        certificatePath: URL,
        privateKeyPath: URL,
        host: String = "0.0.0.0",
        port: Int = 1965,
        numberOfThreads: Int = System.coreCount,
        requestTimeout: Duration = .seconds(30),
    ) {
        self.certificatePath = certificatePath
        self.privateKeyPath = privateKeyPath
        self.host = host
        self.port = port
        self.numberOfThreads = numberOfThreads
        self.requestTimeout = requestTimeout
    }
}

public protocol Server {
    associatedtype Body: Route
    var config: Config { get }

    @RouteBuilder var body: Body { get }

    init()
}

public extension Server {
    static func main() async throws {
        let server = Self()
        try await NIOServer().start(config: server.config, handler: server.body.handler)
    }
}
