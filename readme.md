# GeminiKit

A Swift library for building [Gemini protocol](https://geminiprotocol.net) servers. Provides a declarative, SwiftUI-inspired routing DSL backed by SwiftNIO.

## Requirements

- macOS 26.0+
- Swift 6.3+
- TLS certificate and private key (PEM format)

## Usage

Conform a struct to `Server`, provide a `Config` with your TLS credentials, and declare your routes in `body`:

```swift
import LibServer

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

## Routes

| Route                                  | Description                                           |
| -------------------------------------- | ----------------------------------------------------- |
| `Path("/foo") { ... }`                 | Match an exact path                                   |
| `Match("/foo/:bar") { params in ... }` | Match a path with named parameters                    |
| `Input("Prompt") { response in ... }`  | Prompt the client for input, then handle the response |
| `Success("body")`                      | Return a `20 text/gemini` response                    |

Custom routes can be composed by conforming to `Route` and implementing `body`:

```swift
struct MyRoute: Route {
    var body: some Route {
        Path("/custom") { Success("Custom route") }
    }
}
```

## Response Helpers

```swift
Handler.success("body", mimeType: "text/gemini")
Handler.input("Enter your name:")
Handler.sensitiveInput("Enter your password:")
Handler.redirect(to: "gemini://example.com/new-path")
Handler.permanentRedirect(to: "gemini://example.com/new-path")
Handler.notFound("Page not found")
Handler.failure("Internal error")
Handler.badRequest("Invalid request")
```

## Configuration

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

## Adding as a Dependency

```swift
// Package.swift
.package(url: "https://github.com/boek/geminikit", from: "0.1.0"),

// In your target:
.product(name: "LibServer", package: "geminikit"),
```
