//
//  main.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/1/26.
//

import Foundation

import GeminiServer

let key = try Data(contentsOf: Bundle.module.url(forResource: "key", withExtension: "pem")!)
let cert = try Data(contentsOf: Bundle.module.url(forResource: "cert", withExtension: "pem")!)
let config = GeminiServer.Config(certificate: Certificate(key: key, cert: cert))
let handler = GeminiHandler { request in
    let response = """
       # Welcome to my Gemini capsule

       => /about About this server
       => /hello Hello, world!
       """.data(using: .utf8)!
    
    return .init(status: .success, meta: "text/gemini", body: response)
}
try await GeminiServer.nio.start(config: config, handler: handler)
