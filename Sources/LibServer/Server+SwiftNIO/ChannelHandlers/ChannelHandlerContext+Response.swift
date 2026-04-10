//
//  ChannelHandlerContext+Response.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/9/26.
//

import Core
import NIOCore

extension ChannelHandlerContext {
    func write(response: GeminiResponse, promise: EventLoopPromise<Void>? = nil) {
        var buffer = channel.allocator.buffer(capacity: 256)

        buffer.writeString("\(response.status.rawValue) \(response.meta)\r\n")

        if let body = response.body {
            let byteBuffer = ByteBufferAllocator().buffer(bytes: body)
            buffer.writeImmutableBuffer(byteBuffer)
        }
        write(NIOAny(buffer), promise: promise)
    }
}
