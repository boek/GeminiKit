//
//  App.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

public protocol Route: Sendable {
    var handler: GeminiHandler { get }
}

extension GeminiHandler: Route {
    public var handler: GeminiHandler { self }
}

public protocol App {
    associatedtype Body : Route

    var config: GeminiServer.Config { get }
    @RouteBuilder var body: Self.Body { get }
    
    init()
}

public extension App {
    init() {
        self.init()
    }
    
    static func main() async throws {
        let app = Self()
        try await GeminiServer.nio.start(config: app.config, handler: app.body.handler)
    }
}

@resultBuilder
public struct RouteBuilder {
    public static func buildBlock(_ components: GeminiHandler...) -> GeminiHandler {
        GeminiHandler.choose(routes: Array(components))
    }

    public static func buildExpression(_ expression: some Route) -> GeminiHandler {
        expression.handler
    }
}

public struct Path: Route {
    var path: String
    var routes: @Sendable () -> GeminiHandler
    
    public init(
        _ path: String,
        @RouteBuilder routes: @Sendable @escaping () -> GeminiHandler
    ) {
        self.path = path
        self.routes = routes
    }
    
    public var handler: GeminiHandler { GeminiHandler.path(path, routes()) }
}

public struct Success: Route {
    var body: String
    
    public init(_ body: String) {
        self.body = body
    }
    
    public var handler: GeminiHandler { GeminiHandler.success(body) }
}
