//
//  HTTPClient.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog
import UniformTypeIdentifiers

typealias HTTPResponse = (data: Data, response: HTTPURLResponse)
typealias HTTPResult = Result<HTTPResponse, Error>

/// A class used to communicate with a particular REST API.
final class HTTPClient: Sendable {

    /// The object conforming to `HTTPRequesting` that will be used to perform requests.
    let requestor: HTTPRequesting

    /// The URL relative to which requests should be built.
    let baseURL: URL

    /// The string to send for the `User-Agent` header (if blank, the default for the requestor will be used).
    let userAgent: String?

    /// The string to send for the `Accept-Language` header (if blank, `en` will be used).
    let languageCode: String?

    /// Initializes a new client.
    /// - Parameters:
    ///   - requestor: The object conforming to `HTTPRequesting` that will be used to make requests.
    ///   - baseURL: The URL relative to which requests should be built.
    ///   - userAgent: The string to send for the user agent header.
    ///   - languageCode: The string to send for the accept language header.
    init(requestor: HTTPRequesting, baseURL: URL, userAgent: String?, languageCode: String?) {
        self.requestor = requestor
        self.baseURL = baseURL
        self.userAgent = userAgent
        self.languageCode = languageCode
    }

    /// Performs a request to the specified endpoint.
    /// - Parameter builder: The endpoint for the request.
    /// - Returns: An `HTTPCancellable` instance corresponding to the request.
    /// - Throws: An error if the request fails.
    func request(_ builder: HTTPRequestBuilding) async throws -> HTTPResponse {
        let request = try builder.buildRequest(baseURL: self.baseURL, userAgent: self.userAgent, languageCode: self.languageCode)
        Self.log(request)
        let (rawData, rawResponse) = try await self.requestor.data(for: request)
        let result = try Self.processResult(data: rawData, response: rawResponse)
        Self.log(result)
        return result
    }

    /// Processes the result of a request into an HTTP response object.
    /// - Parameters:
    ///   - data: The data returned in the response, if any.
    ///   - response: The HTTP response, if any.
    /// - Throws: Any errors encountered when processing the request.
    /// - Returns: An HTTP response object consisting of an `HTTPURLResponse` object and response data.
    static func processResult(data: Data?, response: URLResponse?) throws -> HTTPResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.unexpectedResponseType(response)
        }
        switch httpResponse.statusCode {
        case 204:  // No content
            return (Data(), httpResponse)
        case 200...299:
            guard let data else {
                throw HTTPClientError.missingResponseBody
            }
            return (data, httpResponse)
        case 401:
            throw HTTPClientError.unauthorized(httpResponse, data)
        case 400...499:
            throw HTTPClientError.clientError(httpResponse, data)
        case 500...599:
            throw HTTPClientError.serverError(httpResponse, data)
        default:
            throw HTTPClientError.unhandledStatusCode(httpResponse, data)
        }
    }

    static func log(_ request: URLRequest) {
        Logger.network.debug("API \(request.httpMethod ?? "<no method>") to \(request.url?.absoluteString ?? "<no URL>")")

        Logger.network.debug("API request headers:")
        request.allHTTPHeaderFields?.forEach({ (header, value) in
            Logger.network.debug("  \(header): \(value, privacy: .auto)")
        })

        request.httpBody.flatMap { bodyData in
            if let stringValue = String(data: bodyData, encoding: .utf8) {
                Logger.network.debug("Body: \(stringValue)")
            } else {
                Logger.network.debug("Body (base64): \(bodyData.base64EncodedString())")
            }
        }
    }

    static func log(_ response: HTTPResponse) {
        Logger.network.debug("API response from \(response.response.url?.absoluteString ?? "<no URL>"), status \(response.response.statusCode)")

        Logger.network.debug("API response headers:")
        response.response.allHeaderFields.forEach({ (header, value) in
            Logger.network.debug("  \((header as? String) ?? "???"): \((value as? String) ?? "???", privacy: .auto)")
        })

        switch response.data.count {
        case 0:
            Logger.network.debug("Body: <empty>")
        case 1..<1024:
            guard let stringValue = String(data: response.data, encoding: .utf8) else {
                fallthrough
            }
            Logger.network.debug("Body: \(stringValue)")
        default:
            #if DEBUG
                do {
                    let basename = response.response.url?.lastPathComponent ?? "response"
                    let contentType = response.response.value(forHTTPHeaderField: "Content-Type")?.split(separator: ";").first ?? "application/octet-stream"
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent(basename).appendingPathExtension(for: UTType(mimeType: String(contentType)) ?? UTType.data)
                    try response.data.write(to: url)
                    Logger.network.debug("Body: <saved to \(url.path)>")
                } catch {
                    Logger.network.debug("Body: <error saving to /tmp: \(error.localizedDescription)>")
                }
            #else
                Logger.network.debug("Body: <too long to log or not UTF-8>")
            #endif
        }
    }
}

enum HTTPClientError: Error {
    case connectionError(Error)
    case unexpectedResponseType(URLResponse?)
    case missingResponseBody
    case clientError(HTTPURLResponse, Data?)
    case serverError(HTTPURLResponse, Data?)
    case unhandledStatusCode(HTTPURLResponse, Data?)
    case unauthorized(HTTPURLResponse, Data?)
}

extension HTTPClientError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .connectionError(let underlyingError):
            return "Connection error: \(underlyingError.localizedDescription)."

        case .unexpectedResponseType(_):
            return "Unexpected response type (http response was not HTTPURLResponse)."

        case .missingResponseBody:
            return "Missing response body for non-204 status code."

        case .clientError(let response, let data):
            var message = "Client error: \(response.statusCode)."
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                message = "\(message) Response object: \(responseString)"
            }
            return message

        case .serverError(let response, let data):
            var message = "Server error: \(response.statusCode)."
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                message = "\(message) Response object: \(responseString)"
            }
            return message

        case .unhandledStatusCode(let response, _):
            return "Unhandled status code: \(response.statusCode)"

        case .unauthorized(let response, let data):
            var message = "Unauthorized: \(response.statusCode)."
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                message = "\(message) Response object: \(responseString)"
            }
            return message
        }
    }
}

enum HTTPMethod: String, Codable {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}

/// The content type of the request.
struct HTTPContentType {
    // Note: for some reason the charset part is absolutely required by the API for certain multi-part requests
    // (those with both a body and attachments). Adding a space after the semicolon seems to break it.
    // Making it not match the Accept header value also seems to break it (even with an Accept-Charset).
    // You are advised to not change this.
    static let json = "application/json;charset=UTF-8"
    static let octetStream = "application/octet-stream"

    static func multipartMixed(boundary: String) -> String {
        return "multipart/mixed; boundary=\(boundary)"
    }

    static func multipartEncrypted(boundary: String) -> String {
        return "multipart/encrypted; boundary=\(boundary)"
    }
}
