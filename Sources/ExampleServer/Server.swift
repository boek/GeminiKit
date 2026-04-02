//
//  main.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/1/26.
//

import GeminiServer

import Foundation

import NIOCore
import NIOPosix
import NIOSSL

@main
struct GeminiServer {
    static func main() async throws {
        let tlsConfig  = try makeTLSConfiguration()
        let sslContext = try NIOSSLContext(configuration: tlsConfig)

        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        

        let bootstrap = ServerBootstrap(group: group)
            // SO_REUSEADDR lets you restart the server without waiting for the OS to release the port
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                // This closure runs once per accepted connection
                print("🔌 New connection from \(channel.remoteAddress?.description ?? "unknown")")
                return channel.pipeline.addHandlers([
                    NIOSSLServerHandler(context: sslContext),   // 1. TLS unwrap
                    ByteToMessageHandler(GeminiLineDecoder()),  // 2. Buffer → line bytes
                    GeminiRequestDecoder(),                     // 3. Line bytes → GeminiRequest
                    GeminiResponseEncoder(),
                    GeminiHandler(),                            // 4. Request → Response (your logic)
                                        // 5. Response → bytes
                ])
            }

        // Gemini standard port is 1965
        let channel = try await bootstrap.bind(host: "0.0.0.0", port: 1965).get()
        print("Gemini server listening on port 1965")

        try await channel.closeFuture.get()
        try await group.shutdownGracefully()
    }
    
    static func makeTLSConfiguration() throws -> TLSConfiguration {
        let certData = try Data(contentsOf: Bundle.module.url(forResource: "cert", withExtension: "pem")!)
        let keyData = try Data(contentsOf: Bundle.module.url(forResource: "key", withExtension: "pem")!)
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


struct GeminiLineDecoder: ByteToMessageDecoder {
    typealias InboundOut = ByteBuffer

    mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        // Look for \r\n in the readable bytes
        let bytes = buffer.readableBytesView
        guard let crIdx = bytes.firstIndex(where: { $0 == UInt8(ascii: "\r") }),
              bytes.index(after: crIdx) < bytes.endIndex,
              bytes[bytes.index(after: crIdx)] == UInt8(ascii: "\n")
        else {
            return .needMoreData   // tell NIO to call us again when more bytes arrive
        }

        // +2 to include the \r\n itself
        let length = bytes.distance(from: bytes.startIndex, to: crIdx) + 2
        let line = buffer.readSlice(length: length)!
        context.fireChannelRead(wrapInboundOut(line))
        return .continue    // try decoding again immediately (unlikely, but correct)
    }

    mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        return .needMoreData
    }
}
