//
//  HTTPRequesting.swift
//  Apptentive
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias HTTPResult = Result<(data: Data, response: HTTPURLResponse), HTTPRequestError>

protocol HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (HTTPResult) -> Void)
}

extension URLSession: HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (HTTPResult) -> Void) {
        let task = self.dataTask(with: request) { (data, response, error) in
            completion(Self.processResult(data: data, response: response, error: error))
        }

        task.resume()
    }
}

extension HTTPRequesting {
    static func processResult(data: Data?, response: URLResponse?, error: Error?) -> HTTPResult {
        if let error = error {
            return .failure(HTTPRequestError.connectionError(error))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(HTTPRequestError.unexpectedResponseType(response))
        }

        switch httpResponse.statusCode {
        case 200...299:
            if let data = data {
                return .success((data, httpResponse))
            } else if httpResponse.statusCode == 204 {
                // 204 = "No Content", backfill with empty `Data` object
                return .success((Data(), httpResponse))
            } else {
                return .failure(HTTPRequestError.missingResponseBody)
            }
        case 400...499:
            return .failure(HTTPRequestError.clientError(httpResponse, data))
        case 500...599:
            return .failure(HTTPRequestError.serverError(httpResponse, data))
        default:
            return .failure(HTTPRequestError.unhandledStatusCode(httpResponse, data))
        }
    }
}

enum HTTPRequestError: Error {
    case connectionError(Error)
    case unexpectedResponseType(URLResponse?)
    case missingResponseBody
    case clientError(HTTPURLResponse?, Data?)
    case serverError(HTTPURLResponse?, Data?)
    case unhandledStatusCode(HTTPURLResponse?, Data?)
}
