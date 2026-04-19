import Testing
import Foundation
import LibClient

@Suite struct GeminiClientTests {
    let client = GeminiClient()

    @Test func rejectsNonGeminiScheme() async throws {
        await #expect(throws: GeminiClientError.invalidURL) {
            _ = try await client.fetch(URL(string: "https://example.com")!)
        }
    }

    @Test func rejectsMissingHost() async throws {
        await #expect(throws: GeminiClientError.invalidURL) {
            _ = try await client.fetch(URL(string: "gemini:///path")!)
        }
    }

    @Test func rejectsTooLongURL() async throws {
        let path = String(repeating: "a", count: 1010)
        let url = URL(string: "gemini://example.com/\(path)")!
        await #expect(throws: GeminiClientError.requestTooLong) {
            _ = try await client.fetch(url)
        }
    }
}
