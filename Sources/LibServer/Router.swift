//
//  Router.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/9/26.
//

import Foundation
import Core

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
        .input(prompt, next: NextHandler { response in
            return child(response).handler
        })
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
        return .match(path, next: NextHandler { params in
            child(params).handler
        })
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

public struct SensitiveInput<Child: Route>: Route {
    public typealias Body = Never
    public var body: Never { return fatalError() }

    let prompt: String
    let child: @Sendable (String) -> Child

    public init(
        _ prompt: String,
        @RouteBuilder child: @Sendable @escaping (String) -> Child
    ) {
        self.prompt = prompt
        self.child = child
    }
}

extension SensitiveInput: HandlerConvertable {
    var handler: Handler {
        .sensitiveInput(prompt, next: NextHandler { response in child(response).handler })
    }
}

public struct Redirect: Route, HandlerConvertable {
    public typealias Body = Never
    let url: String
    var handler: Handler { Handler { _ in .redirect(to: url) } }
    public var body: Never { return fatalError() }

    public init(to url: String) {
        precondition(URL(string: url) != nil, "Redirect target is not a valid URL: \(url)")
        self.url = url
    }
}

public struct PermanentRedirect: Route, HandlerConvertable {
    public typealias Body = Never
    let url: String
    var handler: Handler { Handler { _ in .permanentRedirect(to: url) } }
    public var body: Never { return fatalError() }

    public init(to url: String) {
        precondition(URL(string: url) != nil, "PermanentRedirect target is not a valid URL: \(url)")
        self.url = url
    }
}

public struct Failure: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .failure(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Temporary failure") { self.reason = reason }
}

public struct ServerUnavailable: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .serverUnavailable(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Server unavailable") { self.reason = reason }
}

public struct CgiError: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .cgiError(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "CGI error") { self.reason = reason }
}

public struct ProxyError: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .proxyError(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Proxy error") { self.reason = reason }
}

public struct SlowDown: Route, HandlerConvertable {
    public typealias Body = Never
    let seconds: Int
    var handler: Handler { Handler { _ in .slowDown(seconds: seconds) } }
    public var body: Never { return fatalError() }

    public init(seconds: Int) { self.seconds = seconds }
}

public struct ServerError: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .serverError(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Server error") { self.reason = reason }
}

public struct NotFound: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .notFound(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Not found") { self.reason = reason }
}

public struct Gone: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .gone(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Gone") { self.reason = reason }
}

public struct BadRequest: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .badRequest(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Bad request") { self.reason = reason }
}

public struct CertificateRequired: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .certificateRequired(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Certificate required") { self.reason = reason }
}

public struct CertificateUnauthorized: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .certificateUnauthorized(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Certificate not authorised") { self.reason = reason }
}

public struct CertificateNotValid: Route, HandlerConvertable {
    public typealias Body = Never
    let reason: String
    var handler: Handler { Handler { _ in .certificateNotValid(reason) } }
    public var body: Never { return fatalError() }

    public init(_ reason: String = "Certificate not valid") { self.reason = reason }
}

public struct RequiresCertificate<Child: Route>: Route {
    public typealias Body = Never
    public var body: Never { return fatalError() }

    let reason: String
    let child: @Sendable (ClientCertificate) -> Child

    public init(
        _ reason: String = "Certificate required",
        @RouteBuilder child: @Sendable @escaping (ClientCertificate) -> Child
    ) {
        self.reason = reason
        self.child = child
    }
}

extension RequiresCertificate: HandlerConvertable {
    var handler: Handler {
        let reason = self.reason
        return Handler { request in
            guard let cert = request.clientCertificate else {
                return .certificateRequired(reason)
            }
            return await child(cert).handler.handle(request: request)
        }
    }
}

extension Path: HandlerConvertable {
    var handler: Handler {
        .path(path, next: child.handler)
    }
}
