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
struct ExampleServer: Server {
    let config = Config(
        certificatePath: Bundle.module.url(forResource: "cert", withExtension: "pem")!,
        privateKeyPath: Bundle.module.url(forResource: "key", withExtension: "pem")!
    )

    var body: some Route {
        Path("/") { Success("Home") }
        Path("/about") { Success("About") }
        Ask()
    }
}


struct Ask: Route {
    var body: some Route {
        Path("/ask") {
            Input("How are you?") { response in
                Success("I'm happy you're \(response)")
            }
        }
    }
}
