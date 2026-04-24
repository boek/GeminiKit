import CryptoKit
import Foundation

public struct CertificateFingerprint: Sendable, Hashable, CustomStringConvertible {
    private let bytes: [UInt8]

    public init(derBytes: [UInt8]) {
        let digest = SHA256.hash(data: Data(derBytes))
        self.bytes = Array(digest)
    }

    public var description: String {
        bytes.map { String(format: "%02x", $0) }.joined(separator: ":")
    }
}

public struct CertificateInfo: Sendable {
    public let host: String
    public let fingerprint: CertificateFingerprint
    public let notAfter: Date
}

public enum CertificateTrust: Sendable {
    case allow
    case reject
}

public struct CertificateVerifier: Sendable {
    private let handler: @Sendable (CertificateInfo) async -> CertificateTrust

    public init(_ handler: @escaping @Sendable (CertificateInfo) async -> CertificateTrust) {
        self.handler = handler
    }

    public func callAsFunction(_ info: CertificateInfo) async -> CertificateTrust {
        await handler(info)
    }

    public static let allowAll = CertificateVerifier { _ in .allow }
}
