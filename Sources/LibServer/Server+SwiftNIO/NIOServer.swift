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
    func start(config: Config, handler: Handler) async throws {
        let tlsConfig  = try makeTLSConfiguration(config: config)
        let sslContext = try NIOSSLContext(configuration: tlsConfig)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        
        let bootstrap = ServerBootstrap(group: group)
            // SO_REUSEADDR lets you restart the server without waiting for the OS to release the port
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        
        let (timeoutSecs, timeoutAtto) = config.requestTimeout.components
        let timeoutAmount = TimeAmount.nanoseconds(timeoutSecs * 1_000_000_000 + timeoutAtto / 1_000_000_000)

        let serverChannel = try await bootstrap.bind(host: config.host, port: config.port) { channel in
            channel.eventLoop.makeCompletedFuture {
                // Accept any client cert without chain verification — Gemini uses fingerprint-based TOFU
                try channel.pipeline.syncOperations.addHandlers(
                    NIOSSLServerHandler(context: sslContext, customVerificationCallback: { _, promise in
                        promise.succeed(.certificateVerified)
                    })
                )
                try channel.pipeline.syncOperations.addHandlers(
                    IdleStateHandler(readTimeout: timeoutAmount),
                    RequestTimeoutHandler()
                )
                try channel.pipeline.syncOperations.addHandlers(ByteToMessageHandler(GeminiLineDecoder()))
                try channel.pipeline.syncOperations.addHandlers(GeminiRequestDecoder(hostname: config.host))
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
                                    let response = await handler.handle(message) ?? GeminiResponse(status: .notFound, meta: "")
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
        let certData = try Data(contentsOf: config.certificatePath)
        let keyData = try Data(contentsOf: config.privateKeyPath)

        let cert = try NIOSSLCertificate(bytes: Array(certData), format: .pem)
        let key  = try NIOSSLPrivateKey(bytes: Array(keyData), format: .pem)

        var config = TLSConfiguration.makeServerConfiguration(
            certificateChain: [.certificate(cert)],
            privateKey: .privateKey(key)
        )
        // Gemini requires TLS 1.2+; 1.3 is preferred
        config.minimumTLSVersion = .tlsv12
        // Request client certs but don't require them — handlers use status 60 to demand one
        config.certificateVerification = .optionalVerification
        return config
    }
}
