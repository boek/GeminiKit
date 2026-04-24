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
