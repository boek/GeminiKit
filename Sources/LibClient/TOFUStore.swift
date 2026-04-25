//
//  TOFUStore.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/25/26.
//

import Core

public struct TOFUStore: Sendable {
    public var trust: @Sendable (CertificateInfo) async -> CertificateTrust

    public init(trust: @Sendable @escaping (CertificateInfo) async -> CertificateTrust) {
        self.trust = trust
    }
}

public extension TOFUStore {
    private actor InMemory {
        private var known: [String: CertificateFingerprint] = [:]

        public init() {}

        public func trust(_ info: CertificateInfo) -> CertificateTrust {
            if let stored = known[info.host] {
                return stored == info.fingerprint ? .allow : .reject
            }
            known[info.host] = info.fingerprint
            return .allow
        }
    }

    static var inMemory: Self {
        let store = InMemory()
        return .init { info in
            await store.trust(info)
        }
    }
}


