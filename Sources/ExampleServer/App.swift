//
//  main.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/1/26.
//

import Foundation

import Core
import LibServer

enum AppError: Error {
    case missingCerts
}

@main
struct ExampleApp {
    static func main() async throws {
        guard let certPath = Bundle.module.url(forResource: "cert", withExtension: "pem"),
              let keyPath = Bundle.module.url(forResource: "key", withExtension: "pem")
        else {
            throw AppError.missingCerts
        }

        let config = Config(certificatePath: certPath, privateKeyPath: keyPath)
        let server = Server(config: config) { request in
            .success("Hello World!")
        }
        try await server.serve()
    }
}
