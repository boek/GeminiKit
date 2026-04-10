//
//  GeminiResponseEncoder.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import Foundation

import NIOCore
import Core

final class GeminiResponseEncoder: ChannelOutboundHandler {
    public typealias OutboundIn = GeminiResponse
    public typealias OutboundOut = ByteBuffer
    
    public init() {}
    
    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let response = self.unwrapOutboundIn(data)
        context.write(response: response, promise: promise)
    }
}
