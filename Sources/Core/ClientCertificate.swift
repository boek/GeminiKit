import Foundation

public struct ClientCertificate: Sendable {
    public let fingerprint: CertificateFingerprint
    public let notAfter: Date

    public init(fingerprint: CertificateFingerprint, notAfter: Date) {
        self.fingerprint = fingerprint
        self.notAfter = notAfter
    }
}
