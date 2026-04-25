# GeminiKit

A Swift library for building [Gemini protocol](https://geminiprotocol.net) servers, with a built-in client and GemText parser. Provides a declarative, SwiftUI-inspired routing DSL backed by SwiftNIO.

## Requirements

- macOS 26.0+
- Swift 6.3+
- TLS certificate and private key (PEM format)

## Server

Conform a struct to `Server`, provide a `Config` with your TLS credentials, and declare your routes in `body`:

```swift
import GeminiKit

@main
struct MyServer: Server {
    let config = Config(
        certificatePath: URL(filePath: "/path/to/cert.pem"),
        privateKeyPath: URL(filePath: "/path/to/key.pem")
    )

    var body: some Route {
        Path("/") { Success("Welcome to my Gemini server!") }

        Path("/about") { Success("About this server") }

        Match("/users/:id") { params in
            if let id = params.id {
                Success("Hello, \(id)!")
            }
        }

        Path("/ask") {
            Input("What is your name?") { name in
                Success("Hello, \(name)!")
            }
        }
    }
}
```

### Routes

**Matching**

| Route | Description |
| ----- | ----------- |
| `Path("/foo") { ... }` | Match an exact path |
| `Match("/foo/:bar") { params in ... }` | Match a path with named parameters |
| `Input("Prompt") { response in ... }` | Prompt the client for input, then handle the response |
| `SensitiveInput("Prompt") { response in ... }` | Prompt for sensitive input (hidden), then handle the response |
| `RequiresCertificate { cert in ... }` | Require a client certificate; passes `ClientCertificate` to the body |

**Responses**

| Route | Status | Description |
| ----- | ------ | ----------- |
| `Success("body")` | 20 | Success with `text/gemini` body |
| `Redirect(to: url)` | 30 | Temporary redirect |
| `PermanentRedirect(to: url)` | 31 | Permanent redirect |
| `Failure("reason")` | 40 | Temporary failure |
| `ServerUnavailable("reason")` | 41 | Server unavailable |
| `CgiError("reason")` | 42 | CGI error |
| `ProxyError("reason")` | 43 | Proxy error |
| `SlowDown(seconds: n)` | 44 | Rate limit; client should retry after `n` seconds |
| `ServerError("reason")` | 50 | Permanent server error |
| `NotFound("reason")` | 51 | Not found |
| `Gone("reason")` | 52 | Resource permanently gone |
| `BadRequest("reason")` | 59 | Bad request |
| `CertificateRequired("reason")` | 60 | Client certificate required |
| `CertificateUnauthorized("reason")` | 61 | Certificate not authorized |
| `CertificateNotValid("reason")` | 62 | Certificate not valid |

Custom routes can be composed by conforming to `Route` and implementing `body`:

```swift
struct MyRoute: Route {
    var body: some Route {
        Path("/custom") { Success("Custom route") }
    }
}
```

### Configuration

```swift
Config(
    certificatePath: URL,       // Path to TLS certificate (PEM)
    privateKeyPath: URL,        // Path to TLS private key (PEM)
    host: String,               // Default: "0.0.0.0"
    port: Int,                  // Default: 1965
    numberOfThreads: Int,       // Default: system core count
    requestTimeout: Duration    // Default: 30 seconds
)
```

## Client

`GeminiClient` fetches Gemini URLs and follows redirects automatically (up to 5 hops). It uses Trust-On-First-Use (TOFU) certificate verification by default:

```swift
import GeminiKit

let client = GeminiClient()
let response = try await client.fetch(URL(string: "gemini://geminiprotocol.net/")!)

if response.status == .success, let data = response.body {
    let text = String(decoding: data, as: UTF8.self)
    print(text)
}
```

To supply a custom certificate policy:

```swift
// Accept all certificates (not recommended for production)
let client = GeminiClient(certificateVerification: .allowAll)

// TOFU with a custom store
let client = GeminiClient(certificateVerification: .tofu(store: myTOFUStore))
```

## GemText

Parse GemText documents into a structured line-by-line representation:

```swift
import GeminiKit

let doc = GemTextDocument(parsing: text)

for line in doc.lines {
    switch line {
    case .text(let s):                        print(s)
    case .heading1(let s):                    print("# \(s)")
    case .heading2(let s):                    print("## \(s)")
    case .heading3(let s):                    print("### \(s)")
    case .listItem(let s):                    print("• \(s)")
    case .blockquote(let s):                  print("> \(s)")
    case .link(let link):                     print("\(link.url)  \(link.label ?? "")")
    case .preformatted(let alt, let lines):   print(lines.joined(separator: "\n"))
    }
}
```

## Adding as a Dependency

```swift
// Package.swift
.package(url: "https://github.com/boek/geminikit", from: "1.0.0"),

// In your target:
.product(name: "GeminiKit", package: "geminikit"),
```
