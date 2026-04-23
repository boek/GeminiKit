import Foundation
import Core
import Foundation

public struct GeminiClient: Sendable {
    public var allowSelfSignedCertificates: Bool

    public init(allowSelfSignedCertificates: Bool = false) {
        self.allowSelfSignedCertificates = allowSelfSignedCertificates
    }

    public func fetch(_ url: URL) async throws -> GeminiResponse {
        guard url.scheme == "gemini", let host = url.host, !host.isEmpty else {
            throw GeminiClientError.invalidURL
        }
        let requestString = url.absoluteString + "\r\n"
        guard requestString.utf8.count <= 1026 else {
            throw GeminiClientError.requestTooLong
        }
        return try await NIOGeminiClient.fetch(
            url: url,
            request: requestString,
            allowSelfSignedCertificates: allowSelfSignedCertificates
        )
    }
}
