import Foundation
import NIOCore
import NIOPosix
import NIOSSL
import Core

enum NIOGeminiClient {
    static func fetch(url: URL, request: String, allowSelfSignedCertificates: Bool) async throws -> GeminiResponse {
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.minimumTLSVersion = .tlsv12
        if allowSelfSignedCertificates {
            tlsConfig.certificateVerification = .none
        }
        let sslContext = try NIOSSLContext(configuration: tlsConfig)

        let host = url.host!
        let port = url.port ?? 1965

        let channel = try await ClientBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .connect(host: host, port: port) { channel in
                channel.eventLoop.makeCompletedFuture {
                    let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: host)
                    try channel.pipeline.syncOperations.addHandler(sslHandler)
                    return try NIOAsyncChannel<ByteBuffer, ByteBuffer>(wrappingChannelSynchronously: channel)
                }
            }

        return try await channel.executeThenClose { inbound, outbound in
            var buffer = ByteBufferAllocator().buffer(capacity: request.utf8.count)
            buffer.writeString(request)
            try await outbound.write(buffer)

            var responseData = Data()
            for try await chunk in inbound {
                var buf = chunk
                if let bytes = buf.readBytes(length: buf.readableBytes) {
                    responseData.append(contentsOf: bytes)
                }
            }

            return try parseResponse(responseData)
        }
    }

    private static func parseResponse(_ data: Data) throws -> GeminiResponse {
        guard let crlfRange = data.range(of: Data([0x0D, 0x0A])) else {
            throw GeminiClientError.invalidResponse
        }

        let headerData = data[..<crlfRange.lowerBound]
        guard let headerLine = String(data: headerData, encoding: .utf8),
              headerLine.count >= 2,
              let statusCode = Int(headerLine.prefix(2)) else {
            throw GeminiClientError.invalidResponse
        }

        guard let status = GeminiStatus(rawValue: statusCode) else {
            throw GeminiClientError.unknownStatus(statusCode)
        }

        let meta = headerLine.count > 3 ? String(headerLine.dropFirst(3)) : ""
        let bodySlice = data[crlfRange.upperBound...]

        return GeminiResponse(
            status: status,
            meta: meta,
            body: bodySlice.isEmpty ? nil : Data(bodySlice)
        )
    }
}
