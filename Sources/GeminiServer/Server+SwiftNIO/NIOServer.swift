//
//  NIOServer.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import NIOCore
import NIOPosix
import NIOSSL

import Core

import Foundation

struct NIOServer {
    func start(config: Config, handler: @escaping GeminiHandler) async throws {
        let tlsConfig  = try makeTLSConfiguration(config: config)
        let sslContext = try NIOSSLContext(configuration: tlsConfig)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        let bootstrap = ServerBootstrap(group: group)
            // SO_REUSEADDR lets you restart the server without waiting for the OS to release the port
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        
        let serverChannel = try await bootstrap.bind(host: "0.0.0.0", port: 1965) { channel in
            channel.eventLoop.makeCompletedFuture {
                try channel.pipeline.syncOperations.addHandlers(NIOSSLServerHandler(context: sslContext))
                try channel.pipeline.syncOperations.addHandlers(ByteToMessageHandler(GeminiLineDecoder()))
                try channel.pipeline.syncOperations.addHandlers(GeminiRequestDecoder())
                try channel.pipeline.syncOperations.addHandlers(GeminiResponseEncoder())
                
                return try NIOAsyncChannel<GeminiRequest, GeminiResponse>(wrappingChannelSynchronously: channel)
            }
        }
        
        try await withThrowingDiscardingTaskGroup { group in
            try await serverChannel.executeThenClose { serverChannelInbound in
                for try await connectionChannel in serverChannelInbound {
                    group.addTask {
                        do {
                            try await connectionChannel.executeThenClose { inbound, outbound in
                                for try await message in inbound {
                                    let response = await handler(message) ?? GeminiResponse(status: .notFound, meta: "")
                                    try await outbound.write(response)
                                    return
                                }
                            }
                        } catch {
                            
                        }
                    }
                }
            }
        }
    }
    
    func makeTLSConfiguration(config: Config) throws -> TLSConfiguration {
        let certData = try Data(contentsOf: config.certPath.appending(path: "cert.pem"))
        let keyData = try Data(contentsOf: config.certPath.appending(path: "key.pem"))
        
        let cert = try NIOSSLCertificate(bytes: Array(certData), format: .pem)
        let key  = try NIOSSLPrivateKey(bytes: Array(keyData), format: .pem)

        var config = TLSConfiguration.makeServerConfiguration(
            certificateChain: [.certificate(cert)],
            privateKey: .privateKey(key)
        )
        // Gemini requires TLS 1.2+; 1.3 is preferred
        config.minimumTLSVersion = .tlsv12
        return config
    }
}

public extension Server {
    func serve() async throws {
        try await NIOServer().start(config: config, handler: handler)
    }
}

