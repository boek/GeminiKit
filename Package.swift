// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GeminiKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "LibServer", targets: ["LibServer"]),
        .library(name: "LibClient", targets: ["LibClient"]),
        .library(name: "LibGemText", targets: ["LibGemText"]),
        .executable(name: "ExampleClient", targets: ["ExampleClient"]),
        .executable(name: "ExampleServer", targets: ["ExampleServer"])
    ],
    dependencies: [ 
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.27.0"),
    ],
    targets: [
        .target(name: "Core"),
        
        .target(name: "LibServer", dependencies: [
            "Core",
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
        ]),
        .testTarget(name: "LibServerTests", dependencies: ["LibServer"]),

        .target(name: "LibClient", dependencies: [
            "Core",
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
        ]),
        .testTarget(name: "LibClientTests", dependencies: ["LibClient"]),

        .target(name: "LibGemText"),
        .testTarget(name: "LibGemTextTests", dependencies: ["LibGemText"]),

        .executableTarget(name: "ExampleClient", dependencies: ["LibClient"]),

        .executableTarget(name: "ExampleServer", dependencies: [
            "LibServer"
        ], resources: [
            .process("cert.pem"),
            .process("key.pem"),
        ]),
    ],
    swiftLanguageModes: [.v6]
)
