import Foundation
import NIOCore
import NIOPosix
import NIOSSL
import Core

enum NIOGeminiClient {
    static func fetch(
        url: URL,
        request: String,
        certificateVerification: CertificateVerifier
    ) async throws -> GeminiResponse {
        var tlsConfig = TLSConfiguration.makeClientConfiguration()
        tlsConfig.minimumTLSVersion = .tlsv12
        let sslContext = try NIOSSLContext(configuration: tlsConfig)

        let host = url.host!
        let port = url.port ?? 1965

        let channel = try await ClientBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .connect(host: host, port: port) { channel in
                channel.eventLoop.makeCompletedFuture {
                    let sslHandler = try NIOSSLClientHandler(
                        context: sslContext,
                        serverHostname: host,
                        customVerificationCallback: { certs, promise in
                            guard let leaf = certs.first,
                                  let derBytes = try? leaf.toDERBytes() else {
                                promise.succeed(.failed)
                                return
                            }
                            let fingerprint = CertificateFingerprint(derBytes: derBytes)
                            let notAfter = Date(timeIntervalSince1970: Double(leaf.notValidAfter))
                            let info = CertificateInfo(host: host, fingerprint: fingerprint, notAfter: notAfter)
                            Task {
                                let trust = await certificateVerification(info)
                                promise.succeed(trust == .allow ? .certificateVerified : .failed)
                            }
                        }
                    )
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

        guard let status = GeminiStatus(classBased: statusCode) else {
            throw GeminiClientError.unknownStatus(statusCode)
        }

        let meta = headerLine.count > 3 ? String(headerLine.dropFirst(3)) : ""
        let bodySlice = data[crlfRange.upperBound...]

        return GeminiResponse(
            status: status,
            meta: meta,
            body: statusCode / 10 == 2 ? (bodySlice.isEmpty ? nil : Data(bodySlice)) : nil
        )
    }
}
