//
//  GeminiRequestDecoder.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import Foundation

import NIOCore
import Core

final class GeminiRequestDecoder: ChannelInboundHandler, RemovableChannelHandler {
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
