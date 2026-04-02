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
        var buffer = context.channel.allocator.buffer(capacity: 256)
        
        buffer.writeString("\(response.status.rawValue) \(response.meta)\r\n")
        
        if let body = response.body {
            let byteBuffer = ByteBufferAllocator().buffer(bytes: body)
            buffer.writeImmutableBuffer(byteBuffer)
        }
        context.write(wrapOutboundOut(buffer), promise: promise)
    }
}
