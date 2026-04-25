import Foundation
import Core

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

    public static func tofu(store: TOFUStore = .inMemory) -> CertificateVerifier {
        CertificateVerifier { info in await store.trust(info) }
    }
}
