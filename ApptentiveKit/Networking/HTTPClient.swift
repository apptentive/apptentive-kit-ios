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
class HTTPClient<Endpoint: HTTPEndpoint> {

    /// The object conforming to `HTTPRequesting` that will be used to perform requests.
    let requestor: HTTPRequesting

    /// The URL relative to which requests should be built.
    let baseURL: URL

    /// The string to send for the `User-Agent` header (if blank, the default for the requestor will be used).
    let userAgent: String?

    /// Initializes a new client.
    /// - Parameters:
    ///   - requestor: The object conforming to `HTTPRequesting` that will be used to make requests.
    ///   - baseURL: The URL relative to which requests should be built.
    ///   - userAgent: The string to send for the user agent header, or nil to use the default one for the requestor.
    init(requestor: HTTPRequesting, baseURL: URL, userAgent: String? = nil) {
        self.requestor = requestor
        self.baseURL = baseURL
        self.userAgent = userAgent
    }

    /// Performs a request to the specified endpoint.
    /// - Parameters:
    ///   - endpoint: The endpoint for the request.
    ///   - completion: A completion handler called with the result of the request.
    /// - Returns: An `HTTPCancellable` instance corresponding to the request.
    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (Result<T, Error>) -> Void) -> HTTPCancellable? {
        do {
            let request = try endpoint.buildRequest(baseURL: self.baseURL, userAgent: self.userAgent)

            let task = requestor.sendRequest(request) { (data, response, error) in
                completion(
                    Result {
                        let httpResponse = try Self.processResult(data: data, response: response, error: error)
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
        case 400...499:
            throw HTTPClientError.clientError(httpResponse, data)
        case 500...599:
            throw HTTPClientError.serverError(httpResponse, data)
        default:
            throw HTTPClientError.unhandledStatusCode(httpResponse, data)
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
            return "Unahndled status code: \(response.statusCode)"
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case delete = "DELETE"
}
