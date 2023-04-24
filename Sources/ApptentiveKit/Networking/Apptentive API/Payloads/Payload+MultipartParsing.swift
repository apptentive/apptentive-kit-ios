//
//  Payload+MultipartParsing.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/23/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

extension Payload {
    struct RawBodyPart {
        let headers: [String: String]
        let content: Data
    }

    /// Replaces the `token` key's value in the first (or only) part of the request body with the new token.
    ///
    /// This assumes certain things about the Apptentive payload structure and will not work with arbitrary request bodies.
    /// - Parameters:
    ///   - embeddedToken: The new token to use when upating the request.
    ///   - encoder: A reusable `JSONEncoder` object (since this is called once per queued payload).
    ///   - decoder: A reusable `JSONDecoder` object (since this is called once per queued payoad).
    ///   - encryptionKey: The encryption key to use to decrypt and re-encrypt the payload.
    /// - Throws: an error if the `bodyData` can't be parsed or if the updated body can't be encoded.
    mutating func updateEmbeddedToken(_ embeddedToken: String, encoder: JSONEncoder, decoder: JSONDecoder, encryptionKey: Data) throws {
        let bodyParts = try Self.parseBodyData(of: self, using: decoder, encryptionKey: encryptionKey)

        guard var jsonObject = bodyParts.first as? JSONObject else {
            throw MultipartParseError.internalInconsistency
        }

        jsonObject.embeddedToken = embeddedToken

        let isMultipart = jsonObject.specializedJSONObject.containerKey?.rawValue == "message"
        let updatedFirstPart = EncryptedHTTPBodyPart(bodyPart: jsonObject, encryptionKey: encryptionKey, includeHeaders: isMultipart)
        let newBodyParts = [updatedFirstPart] + bodyParts.suffix(from: 1)

        (self.contentType, self.bodyData) = try Self.encodeBodyData(from: newBodyParts, encryptionKey: encryptionKey, using: encoder, isMultipart: isMultipart)
    }

    static func parseParameters(from headerValue: String) throws -> [String: String] {
        let parameters = try headerValue.components(separatedBy: ";").suffix(from: 1).map { (component) -> (String, String) in
            let keyAndValue = component.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "=").map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\" \r\n\t")) }

            guard keyAndValue.count == 2 else {
                throw MultipartParseError.unableToParseParameter
            }

            return (keyAndValue[0], keyAndValue[1])
        }

        return Dictionary(parameters) { old, new in return old }
    }

    static func parseBodyData(of payload: Payload, using decoder: JSONDecoder, encryptionKey: Data) throws -> [HTTPBodyPart] {
        guard let contentType = payload.contentType, var bodyData = payload.bodyData else {
            return []
        }

        if contentType.hasPrefix("multipart") {
            guard let boundary = try self.parseParameters(from: contentType)["boundary"] else {
                throw MultipartParseError.invalidBoundary
            }

            let rawBodyParts = try self.parseMultipartBody(bodyData, boundary: boundary)

            let result: [HTTPBodyPart] = try rawBodyParts.map { try self.convertToHTTPBodyPart($0, using: decoder, encryptionKey: encryptionKey) }

            return result
        } else {
            if contentType == HTTPContentType.octetStream {
                bodyData = try bodyData.decrypted(with: encryptionKey)
            }

            return [try decoder.decode(JSONObject.self, from: bodyData)]
        }
    }

    static func convertToHTTPBodyPart(_ rawPart: RawBodyPart, using decoder: JSONDecoder, encryptionKey: Data) throws -> HTTPBodyPart {
        switch rawPart.headers["Content-Type"] {
        case .none:
            throw MultipartParseError.invalidPart

        case HTTPContentType.json:
            return try decoder.decode(JSONObject.self, from: rawPart.content)

        case HTTPContentType.octetStream:
            let plaintextContent = try rawPart.content.decrypted(with: encryptionKey)
            let innerRawPart = try self.parseMultipartPart(plaintextContent)

            if innerRawPart.headers["Content-Type"] == HTTPContentType.json {
                return try decoder.decode(JSONObject.self, from: innerRawPart.content)
            } else {
                guard let innerContentType = innerRawPart.headers["Content-Type"],
                    let innerContentDisposition = innerRawPart.headers["Content-Disposition"]
                else {
                    throw MultipartParseError.invalidPart
                }
                let parameters = try self.parseParameters(from: innerContentDisposition)

                return Attachment(contentType: innerContentType, filename: parameters["filename"], contents: .data(innerRawPart.content))
            }

        case .some(let contentType):
            guard let contentDisposition = rawPart.headers["Content-Disposition"] else {
                throw MultipartParseError.internalInconsistency
            }

            let parameters = try self.parseParameters(from: contentDisposition)

            return Attachment(contentType: contentType, filename: parameters["filename"], contents: .data(rawPart.content))
        }
    }

    static func parseMultipartBody(_ body: Data, boundary boundaryString: String) throws -> [RawBodyPart] {
        guard let boundary = boundaryString.data(using: .utf8),
            let crlf = "\r\n".data(using: .utf8),
            let dashes = "--".data(using: .utf8)
        else {
            throw MultipartParseError.internalInconsistency
        }

        var index = 0
        var result = [RawBodyPart]()

        while index < body.count {
            var partRange: Range<Data.Index>

            if let firstBoundaryIndex = body.range(of: dashes + boundary + crlf, in: 0..<body.count), index == 0 {
                index = firstBoundaryIndex.endIndex
                continue
            } else if let nextBoundaryIndex = body.range(of: crlf + dashes + boundary + crlf, in: index..<body.count) {
                partRange = index..<nextBoundaryIndex.startIndex
                index = nextBoundaryIndex.endIndex
            } else if let finalBoundaryIndex = body.range(of: crlf + dashes + boundary + dashes, in: index..<body.count) {
                partRange = index..<finalBoundaryIndex.startIndex
                index = body.count
            } else {
                throw MultipartParseError.invalidBoundary
            }

            result.append(try self.parseMultipartPart(body.subdata(in: partRange)))
        }

        return result
    }

    static func parseMultipartPart(_ part: Data) throws -> RawBodyPart {
        guard let crlf = "\r\n".data(using: .utf8) else {
            throw MultipartParseError.internalInconsistency
        }

        var headers = [String: String]()

        var currentIndex = 0

        while currentIndex < part.count {
            guard let nextCRLFIndex = part.range(of: crlf, in: currentIndex..<part.count) else {
                throw MultipartParseError.invalidHeader
            }

            let line = part[currentIndex..<nextCRLFIndex.startIndex]

            currentIndex = nextCRLFIndex.endIndex

            if line.isEmpty {
                // End of headers
                break
            }

            guard let header = String(data: line, encoding: .utf8) else {
                throw MultipartParseError.invalidHeader
            }

            let parts = header.split(separator: ":")

            guard parts.count == 2 else {
                throw MultipartParseError.invalidHeader
            }

            let headerName = parts[0].trimmingCharacters(in: .whitespaces)
            let headerValue = parts[1].trimmingCharacters(in: .whitespaces)

            headers[headerName] = headerValue
        }

        let content = Data(part.suffix(from: currentIndex))

        return RawBodyPart(headers: headers, content: content)
    }

    enum MultipartParseError: Swift.Error {
        case internalInconsistency
        case invalidContentType
        case invalidBoundary
        case unableToParseParameter
        case invalidHeader
        case invalidPart
    }
}
