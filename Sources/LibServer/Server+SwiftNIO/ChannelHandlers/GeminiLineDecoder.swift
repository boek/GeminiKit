//
//  GeminiLineDecoder.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import NIOCore

struct GeminiLineDecoder: ByteToMessageDecoder {
    typealias InboundOut = ByteBuffer

    mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        // Look for \r\n in the readable bytes
        let bytes = buffer.readableBytesView
        guard let crIdx = bytes.firstIndex(where: { $0 == UInt8(ascii: "\r") }),
              bytes.index(after: crIdx) < bytes.endIndex,
              bytes[bytes.index(after: crIdx)] == UInt8(ascii: "\n")
        else {
            if buffer.readableBytes > 1026 {
                context.close(promise: nil)
            }
            return .needMoreData   // tell NIO to call us again when more bytes arrive
        }

        // +2 to include the \r\n itself
        let length = bytes.distance(from: bytes.startIndex, to: crIdx) + 2
        let line = buffer.readSlice(length: length)!
        context.fireChannelRead(wrapInboundOut(line))
        return .continue    // try decoding again immediately (unlikely, but correct)
    }

    mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        return .needMoreData
    }
}
