public enum GeminiClientError: Error, Sendable, Equatable {
    case invalidURL
    case requestTooLong
    case invalidResponse
    case unknownStatus(Int)
    case tooManyRedirects
}
