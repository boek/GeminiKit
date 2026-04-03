//
//  main.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/1/26.
//

import Foundation

import GeminiServer


//let handler = GeminiHandler { request in
//    let response = """
//       # Welcome to my Gemini capsule
//
//       => /about About this server
//       => /hello Hello, world!
//       """.data(using: .utf8)!
//    
//    return .init(status: .success, meta: "text/gemini", body: response)
//}


@main
struct ExampleApp: App {
    var config: GeminiServer.Config {
        let key = try! Data(contentsOf: Bundle.module.url(forResource: "key", withExtension: "pem")!)
        let cert = try! Data(contentsOf: Bundle.module.url(forResource: "cert", withExtension: "pem")!)
        return GeminiServer.Config(certificate: Certificate(key: key, cert: cert))
    }
    
    var body: some Route {
        About()
        Home()
    }
}

struct About: Route {
    var body: some Route {
        Path("/about") {
            Path("/jeff") {
                Success("Hello Jeff")
            }
            
            Path("/sam") {
                Success("Hello Sam")
            }
            
            Success("This is the about")
        }

    }
    
    var handler: GeminiHandler { body.handler }
}


struct Home: Route {
    var body: some Route {
        Path("/") {
            Success("Home")
        }

    }
    
    var handler: GeminiHandler { body.handler }
}
