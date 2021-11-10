//
//  HTTPBodyPart.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/8/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias mediaType = String

/// Defines the body of an HTTP request, or for multipart requests, one of the parts of the body of the request.
struct HTTPBodyPart: Encodable {
    let contentDisposition: String
    let contentType: String
    let content: BodyPartData

    init(contentDisposition: String, contentType: String, data: BodyPartData) {
        self.contentDisposition = contentDisposition
        self.contentType = contentType
        self.content = data
    }

    static func jsonEncoded(_ encodable: Encodable, name: String? = nil) -> Self {
        return self.init(contentDisposition: "form-data; name=\"\(name ?? "data")\"", contentType: HTTPContentType.json, data: .jsonEncoded(encodable))
    }

    static func raw(_ data: Data, mediaType: String, filename: String? = nil, parameterName: String? = nil) -> Self {
        return self.init(contentDisposition: "form-data; name=\"\(parameterName ?? "file[]")\"; filename=\"\(filename ?? "File")\"", contentType: mediaType, data: .raw(data))
    }

    func content(using encoder: JSONEncoder) throws -> Data {
        switch self.content {
        case .raw(let data):
            return data

        case .jsonEncoded:
            return try encoder.encode(self.content)
        }
    }

    /// Describes the content of a body part, either as raw `Data` or an unencoded JSON-encodable object.
    ///
    /// In order to make building requests non-throwing, the conversion of a JSON-encodable body part
    /// is deferred until the request is converted to a `URLRequest`, meaning that all content
    /// can't be stored as a raw `Data` object.
    enum BodyPartData: Encodable {
        case raw(Data)
        case jsonEncoded(Encodable)

        func encode(to encoder: Encoder) throws {
            switch self {
            case .jsonEncoded(let encodable):
                return try encodable.encode(to: encoder)

            default:
                throw ApptentiveError.internalInconsistency
            }
        }
    }
}
