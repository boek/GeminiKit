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

        var meta = response.meta
        while meta.utf8.count > 1024 { meta.removeLast() }
        buffer.writeString("\(response.status.rawValue) \(meta)\r\n")

        if response.status == .success, let body = response.body {
            let byteBuffer = ByteBufferAllocator().buffer(bytes: body)
            buffer.writeImmutableBuffer(byteBuffer)
        }
        write(NIOAny(buffer), promise: promise)
    }
}
