import Core
import Foundation

public struct GeminiClient: Sendable {
    public var certificateVerification: CertificateVerifier

    public init(certificateVerification: CertificateVerifier = .tofu()) {
        self.certificateVerification = certificateVerification
    }

    public func fetch(_ url: URL) async throws -> GeminiResponse {
        var current = url
        for _ in 0..<5 {
            guard current.scheme == "gemini",
                  let host = current.host, !host.isEmpty,
                  current.user == nil, current.password == nil else {
                throw GeminiClientError.invalidURL
            }
            let requestString = current.absoluteString + "\r\n"
            guard requestString.utf8.count <= 1026 else {
                throw GeminiClientError.requestTooLong
            }
            let response = try await NIOGeminiClient.fetch(
                url: current,
                request: requestString,
                certificateVerification: certificateVerification
            )
            switch response.status {
            case .redirect, .redirectPermanent:
                guard let next = URL(string: response.meta, relativeTo: current)?.absoluteURL else {
                    throw GeminiClientError.invalidResponse
                }
                current = next
            default:
                return response
            }
        }
        throw GeminiClientError.tooManyRedirects
    }
}
