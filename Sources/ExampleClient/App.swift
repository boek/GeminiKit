import GeminiKit

@main struct App {
    static func main() async throws {
        let client = GeminiClient(allowSelfSignedCertificates: true)
        let url = URL(string: "gemini://geminiprotocol.net/")!
        let response = try await client.fetch(url)

        print("Status: \(response.status)")
        print("Meta:   \(response.meta)")
        if let body = response.body, let text = String(data: body, encoding: .utf8) {
            print(text)
        }
    }
}
