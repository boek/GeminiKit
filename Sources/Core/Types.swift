//
//  Types.swift
//  GeminiServer
//
//  Created by Jeff Boek on 4/1/26.
//

import Foundation

public struct GeminiRequest {
    public var url: URL
    
    public init(url: URL) {
        self.url = url
    }
}

public enum GeminiStatus: Int {
    case success            = 20
    case redirect           = 30
    case redirectPermanent  = 31
    case temporaryFailure   = 40
    case notFound           = 51
    case serverError        = 50
}

public struct GeminiResponse {
    public var status: GeminiStatus
    public var meta: String
    public var body: Data?
    
    public init(status: GeminiStatus, meta: String, body: Data? = nil) {
        self.status = status
        self.meta = meta
        self.body = body
    }
}
