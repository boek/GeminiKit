import Foundation

public struct GemTextLink: Sendable, Equatable {
    public let url: URL
    public let label: String?

    public init(url: URL, label: String? = nil) {
        self.url = url
        self.label = label
    }
}
