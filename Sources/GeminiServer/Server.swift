//
//  Server.swift
//  GeminiServer
//
//  Created by Jeff Boek on 4/1/26.
//

import Core
import LibNetworking

import Foundation
import NIOCore

public final class GeminiRequestDecoder: ChannelInboundHandler, RemovableChannelHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = GeminiRequest
    
    private var buffer = ""
    
    public init() {}
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buf = unwrapInboundIn(data)
        guard let line = buf.readString(length: buf.readableBytes) else {
            print("❌ Decoder: couldn't read string from buffer")
            return
        }
        print("📥 Decoder received: \(line.debugDescription)")
        buffer += line
        
        guard buffer.hasSuffix("\r\n") else { return }
        
        let rawLine = buffer.trimmingCharacters(in: .newlines)
        buffer = ""
        
        guard
            rawLine.count <= 1024,
            let url = URL(string: rawLine),
            url.scheme?.lowercased() == "gemini"
        else {
            let response = GeminiResponse(status: .temporaryFailure, meta: "Bad request")
            context.fireChannelRead(wrapInboundOut(GeminiRequest(url: URL(string: "gemini://invalid")!)))
            return
        }
        
        context.fireChannelRead(wrapInboundOut(GeminiRequest(url: url)))
    }
}

public final class GeminiResponseEncoder: ChannelOutboundHandler {
    public typealias OutboundIn = GeminiResponse
    public typealias OutboundOut = ByteBuffer
    
    public init() {}
    
    public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let response = self.unwrapOutboundIn(data)
        var buffer = context.channel.allocator.buffer(capacity: 256)
        
        
        buffer.writeString("\(response.status.rawValue) \(response.meta.count)\r\n")
        
        if let body = response.body {
            let byteBuffer = ByteBufferAllocator().buffer(bytes: body)
            buffer.writeImmutableBuffer(byteBuffer)
        }
        context.write(wrapOutboundOut(buffer), promise: promise)
    }
}

public final class GeminiHandler: ChannelInboundHandler {
    public typealias InboundIn = GeminiRequest
    public typealias InboundOut = Never
    
    public init() {}
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let request = unwrapInboundIn(data)
        print("📨 Handler received request for: \(request.url)")
        let response = handle(request: request, allocator: context.channel.allocator)
        print("📤 Handler sending response: \(response.status) \(response.meta)")
        
        context.channel.writeAndFlush(response).whenComplete { result in
            print("✅ Write complete: \(result)")
            context.close(promise: nil)
        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: any Error) {
        print("💥 Error: \(error)")
        context.close(promise: nil)
    }
    
    private func handle(
        request: GeminiRequest,
        allocator: ByteBufferAllocator
    ) -> GeminiResponse {
        let path = request.url.path.isEmpty ? "/" : request.url.path
        
        switch path {
        case "/":
            let response = """
           # Welcome to my Gemini capsule
           
           => /about About this server
           => /hello Hello, world!
           """.data(using: .utf8)!
            
           return GeminiResponse(status: .success, meta: "text/gemini; charset=utf-8", body: response)

        case "/hello":
            let body = "Hello from SwiftNIO!\n".data(using: .utf8)!
            return GeminiResponse(status: .success, meta: "text/plain", body: body)

        default:
           return GeminiResponse(status: .notFound, meta: "Not found: \(path)", body: nil)
        }
    }
}
