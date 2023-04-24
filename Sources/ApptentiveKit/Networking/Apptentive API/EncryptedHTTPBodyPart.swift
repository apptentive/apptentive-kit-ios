//
//  EncryptedHTTPBodyPart.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/8/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct EncryptedHTTPBodyPart: HTTPBodyPart {
    let bodyPart: HTTPBodyPart

    let encryptionKey: Data

    let includeHeaders: Bool

    init(bodyPart: HTTPBodyPart, encryptionKey: Data, includeHeaders: Bool) {
        self.bodyPart = bodyPart
        self.encryptionKey = encryptionKey
        self.includeHeaders = includeHeaders
    }

    var contentType: String {
        return HTTPContentType.octetStream
    }

    var filename: String? {
        return bodyPart.filename
    }

    var parameterName: String? {
        return bodyPart.parameterName
    }

    func content(using encoder: JSONEncoder) throws -> Data {
        //        guard let crlf = "\r\n".data(using: .utf8) else {
        //            throw ApptentiveError.internalInconsistency
        //        }

        var result = try self.bodyPart.content(using: encoder)

        if self.includeHeaders {
            // TODO: Re-add trailing newline pending server-side fix.
            result = try Self.multipartHeaders(for: self.bodyPart) + result  // + crlf
        }

        return try result.encrypted(with: self.encryptionKey)
    }

    static func multipartHeaders(for bodyPart: HTTPBodyPart) throws -> Data {
        guard let crlf = "\r\n".data(using: .utf8),
            let contentDispositionHeader = "Content-Disposition: \(bodyPart.contentDisposition)".data(using: .utf8),
            let contentTypeHeader = "Content-Type: \(bodyPart.contentType)".data(using: .utf8)
        else {
            throw ApptentiveError.internalInconsistency
        }

        var result = Data()

        result.append(contentDispositionHeader + crlf)
        result.append(contentTypeHeader + crlf)
        result.append(crlf)

        return result
    }
}
