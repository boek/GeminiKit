//
//  main.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/1/26.
//

import Foundation

import GeminiServer

@main
struct ExampleApp {
    static func main() async throws {
        let config = Config(certPath: Bundle.module.resourceURL!)
        let server = Server(config: config) { request in
                .success("Hello World!")
        }
        try await server.serve()
    }
}
