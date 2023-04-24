//
//  HTTPClient.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias HTTPResponse = (data: Data, response: HTTPURLResponse)
typealias HTTPResult = Result<HTTPResponse, Error>

/// A class used to communicate with a particular REST API.
class HTTPClient {

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
    /// - Parameters:
    ///   - endpoint: The endpoint for the request.
    ///   - completion: A completion handler called with the result of the request.
    /// - Returns: An `HTTPCancellable` instance corresponding to the request.
    @discardableResult
    func request<T: Decodable>(_ endpoint: HTTPRequestBuilding, completion: @escaping (Result<T, Error>) -> Void) -> HTTPCancellable? {
        do {
            let request = try endpoint.buildRequest(baseURL: self.baseURL, userAgent: self.userAgent, languageCode: self.languageCode)

            Self.log(request)

            let task = requestor.sendRequest(request) { (data, response, error) in
                completion(
                    Result {
                        let httpResponse = try Self.processResult(data: data, response: response, error: error)

                        Self.log(httpResponse)

                        return try endpoint.transformResponse(httpResponse)
                    })
            }

            return task
        } catch let error {
            completion(.failure(error))

            return nil
        }
    }

    /// Processes the result of a request into an HTTP response object.
    /// - Parameters:
    ///   - data: The data returned in the response, if any.
    ///   - response: The HTTP response, if any.
    ///   - error: The error encountered during the request, if any.
    /// - Throws: Any errors encountered when processing the request.
    /// - Returns: An HTTP response object consisting of an `HTTPURLResponse` object and response data.
    static func processResult(data: Data?, response: URLResponse?, error: Error?) throws -> HTTPResponse {
        if let error = error {
            throw HTTPClientError.connectionError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPClientError.unexpectedResponseType(response)
        }

        switch httpResponse.statusCode {
        case 200...299:
            if let data = data {
                return (data, httpResponse)
            } else if httpResponse.statusCode == 204 {
                // 204 = "No Content", backfill with empty `Data` object.
                return (Data(), httpResponse)
            } else {
                throw HTTPClientError.missingResponseBody
            }
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
        ApptentiveLogger.network.debug("API \(request.httpMethod ?? "<no method>") to \(request.url?.absoluteString ?? "<no URL>")")

        ApptentiveLogger.network.debug("API request headers:")
        request.allHTTPHeaderFields?.forEach({ (header, value) in
            ApptentiveLogger.network.debug("  \(header): \(value, privacy: .auto)")
        })

        request.httpBody.flatMap {
            if request.allHTTPHeaderFields?["Content-Type"]?.contains("multipart") ?? false {
                ApptentiveLogger.network.debug("Body: <multipart>")
            } else {
                // It's likely this is either plain text or JSON, so it can be treated as a string.
                ApptentiveLogger.network.debug("Body: \(String(data: $0, encoding: .utf8) ?? "<not plain utf-8>")")
            }
        }
    }

    static func log(_ response: HTTPResponse) {
        ApptentiveLogger.network.debug("API response from \(response.response.url?.absoluteString ?? "<no URL>"), status \(response.response.statusCode)")

        ApptentiveLogger.network.debug("API response headers:")
        response.response.allHeaderFields.forEach({ (header, value) in
            ApptentiveLogger.network.debug("  \((header as? String) ?? "???"): \((value as? String) ?? "???", privacy: .auto)")
        })

        if response.data.count > 0 {
            ApptentiveLogger.network.debug("Body: \(String(data: response.data, encoding: .utf8) ?? "<encoding error>")")
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
