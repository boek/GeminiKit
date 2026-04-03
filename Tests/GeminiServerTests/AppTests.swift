//
//  Test.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import Foundation

import Testing
import GeminiServer

@Suite("App: Hello World")
struct HelloWorld: App {
    let config = GeminiServer.Config(certificate: .init(key: .init(), cert: .init()))
    
    var body: some Route {
        Success("Hello Wrold")
    }
    
    @Test func weGetTheExpectedResponse() async throws {
        let response = try await self.body.handler(.init(url: URL(string: "/")!))
        print("message")
        #expect(response?.status == .success)
    }
}
