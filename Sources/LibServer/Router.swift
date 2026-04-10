//
//  Router.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/9/26.
//

public protocol Route: Sendable {
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

struct IfRoute: Route, HandlerConvertable {
    typealias Body = Never

    var handler: Handler

    init(route: (any Route)?) {
        self.handler = route?.handler ?? Handler { _ in nil }
    }

    var body: Never { return fatalError() }
}


@resultBuilder
public enum RouteBuilder {
    public static func buildBlock(_ components: any Route...) -> some Route {
        RootRoute(handlers: components.map(\.handler))
    }

    public static func buildOptional(_ component: (any Route)?) -> some Route {
        IfRoute(route: component)
    }

    public static func buildEither(first component: some Route) -> some Route {
        component
    }

    public static func buildEither(second component: some Route) -> some Route {
        component
    }
}

public struct Input<Child: Route>: Route {
    public typealias Body = Never
    public var body: Never { return fatalError() }

    let prompt: String
    let child: @Sendable (String) -> Child

    public init(
        _ prompt: String,
        @RouteBuilder child: @Sendable @escaping (String) -> Child) {
        self.prompt = prompt
        self.child = child
    }
}

extension Input: HandlerConvertable {
    var handler: Handler {
        .input(prompt) { response in
            return child(response).handler
        }
    }
}
@dynamicMemberLookup
public struct Parameters: Sendable {
    let parameters: [String: String]

    init(path: String, compared: String) {
        let templateParts = path.split(separator: "/", omittingEmptySubsequences: false)
        let actualParts = compared.split(separator: "/", omittingEmptySubsequences: false)

        guard templateParts.count == actualParts.count else {
            parameters = [:]
            return
        }

        parameters = zip(templateParts, actualParts)
            .reduce(into: [:]) { result, pair in
                let (template, actual) = pair
                if template.hasPrefix(":") {
                    let key = String(template.dropFirst())
                    result[key] = String(actual)
                }
            }
    }

    public subscript(dynamicMember member: String) -> String? {
        parameters[member]
    }
}

public struct Match<Child: Route>: Route {
    public typealias Body = Never
    public var body: Never { return fatalError() }

    let path: String
    let child: @Sendable (Parameters) -> Child

    public init(
        _ path: String,
        @RouteBuilder child: @Sendable @escaping (Parameters) -> Child
    ) {
        self.path = path
        self.child = child
    }
}

extension Match: HandlerConvertable {
    var handler: Handler {
        return .match(path) { params in
            child(params).handler
        }
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
