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

class HTTPClient<Endpoint: HTTPEndpoint> {
    let requestor: HTTPRequesting
    let baseURL: URL

    init(requestor: HTTPRequesting, baseURL: URL) {
        self.requestor = requestor
        self.baseURL = baseURL
    }

    @discardableResult
    func request<T: Decodable>(_ endpoint: Endpoint, completion: @escaping (Result<T, Error>) -> Void) -> HTTPCancellable? {
        do {
            let request = try endpoint.buildRequest(baseURL: self.baseURL)

            let task = requestor.sendRequest(request) { (data, response, error) in
                completion(
                    Result {
                        let httpResponse = try Self.processResult(data: data, response: response, error: error)
                        return try Endpoint.transformResponseData(httpResponse.data)
                    })
            }

            return task
        } catch let error {
            completion(.failure(error))

            return nil
        }
    }

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
                // 204 = "No Content", backfill with empty `Data` object
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

    var localizedDescription: String {
        switch self {
        case .connectionError(let underlyingError):
            return "Connection error: \(underlyingError.localizedDescription)."

        case .unexpectedResponseType(_):
            return "Unexpected response type (http response was not HTTPURLResponse)."

        case .missingResponseBody:
            return "Missing response body for non-204 status code."

        case .clientError(let response, _):
            return "Client error: \(response.statusCode)"

        case .serverError(let response, _):
            return "Server Error: \(response.statusCode)"

        case .unhandledStatusCode(let response, _):
            return "Unahndled status code: \(response.statusCode)"
        }
    }
}
