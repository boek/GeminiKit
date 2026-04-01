// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GeminiKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "GeminiServer", targets: ["GeminiServer"]),
        .executable(name: "ExampleServer", targets: ["ExampleServer"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.27.0"),
    ],
    targets: [
        .target(name: "Core"),
        
        .target(name: "GeminiServer", dependencies: [
            "Core",
            "LibNetworking"
        ]),
        
        .executableTarget(name: "ExampleServer", dependencies: [
            "GeminiServer"
        ], resources: [
            .process("cert.pem"),
            .process("key.pem"),
        ]),
        
        .target(name: "LibNetworking", dependencies: [
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOPosix", package: "swift-nio"),
            .product(name: "NIOSSL", package: "swift-nio-ssl"),
        ]),
        .testTarget(name: "LibNetworkingTests", dependencies: ["LibNetworking"]),
    ],
    swiftLanguageModes: [.v6]
)
