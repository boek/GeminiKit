//
//  GeminiRequestDecoder.swift
//  GeminiKit
//
//  Created by Jeff Boek on 4/2/26.
//

import Foundation

import NIOCore
import NIOSSL
import Core

final class GeminiRequestDecoder: ChannelInboundHandler, RemovableChannelHandler {
    public typealias InboundIn = ByteBuffer
    public typealias InboundOut = GeminiRequest

    private var buffer = ""
    private var clientCertificate: ClientCertificate?

    public init() {}

    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        if clientCertificate == nil,
           let sslHandler = try? context.channel.pipeline.syncOperations.handler(type: NIOSSLServerHandler.self),
           let cert = sslHandler.peerCertificate,
           let derBytes = try? cert.toDERBytes() {
            let fingerprint = CertificateFingerprint(derBytes: derBytes)
            let notAfter = Date(timeIntervalSince1970: Double(cert.notValidAfter))
            clientCertificate = ClientCertificate(fingerprint: fingerprint, notAfter: notAfter)
        }

        var buf = unwrapInboundIn(data)
        guard let line = buf.readString(length: buf.readableBytes) else {
            return
        }

        buffer += line

        guard buffer.hasSuffix("\r\n") else { return }

        let rawLine = buffer.trimmingCharacters(in: .newlines)
        buffer = ""

        guard
            rawLine.utf8.count <= 1024,
            let url = URL(string: rawLine),
            url.scheme?.lowercased() == "gemini"
        else {
            let response = GeminiResponse(status: .badRequest, meta: "Bad request")
            context.write(response: response)
            return
        }

        context.fireChannelRead(wrapInboundOut(GeminiRequest(url: url, clientCertificate: clientCertificate)))
    }
}
