//
//  RequestTimeoutHandler.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/25/26.
//

import NIOCore

final class RequestTimeoutHandler: ChannelInboundHandler, RemovableChannelHandler {
    typealias InboundIn = ByteBuffer

    func userInboundEventTriggered(context: ChannelHandlerContext, event: Any) {
        if (event as? IdleStateHandler.IdleStateEvent) == .read {
            context.close(promise: nil)
        } else {
            context.fireUserInboundEventTriggered(event)
        }
    }
}
