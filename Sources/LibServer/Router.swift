//
//  Router.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/9/26.
//

public protocol Route {
    associatedtype Body: Route

    @RouteBuilder var body: Body { get }
}

extension Route {
    var handler: Handler {
        if let converted = self as? HandlerConvertable {
            return converted.handler
        }

        return body.handler
    }
}

extension Never: Route {
    public typealias Body = Never
    public var body: Never { return fatalError("Never does not have a body") }
}

struct RootRoute: Route, HandlerConvertable {
    typealias Body = Never
    var handlers: [Handler]

    var handler: Handler {
        .choose(handlers)
    }

    var body: Never { return fatalError() }
}


@resultBuilder
public enum RouteBuilder {
    public static func buildBlock(_ components: any Route...) -> some Route {
        RootRoute(handlers: components.map(\.handler))
    }

    public static func buildPartialBlock(first: any Route) -> some Route {
        RootRoute(handlers: [first.handler])
    }

    public static func buildPartialBlock(accumulated: any Route, next: any Route) -> some Route {
        RootRoute(handlers: [accumulated.handler, next.handler])
    }
}

public struct Path<Child: Route>: Route {
    public typealias Body = Never
    public var body: Never { return fatalError() }

    let path: String
    let child: Child

    public init(
        _ path: String,
        @RouteBuilder child: () -> Child
    ) {
        self.path = path
        self.child = child()
    }
}

public struct Success: Route, HandlerConvertable {
    public typealias Body = Never
    var content: String
    var handler: Handler { .success(content) }
    public var body: Never { return fatalError() }
    
    public init(_ content: String) {
        self.content = content
    }
}

extension Path: HandlerConvertable {
    var handler: Handler {
        .path(path, next: child.handler)
    }
}
