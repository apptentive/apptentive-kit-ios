//
//  HTTPEndpoint.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/12/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Includes the methods and variables needed to describe an API endpoint.
protocol HTTPEndpoint {
    var method: HTTPMethod { get }

    func headers() throws -> [String: String]
    func url(relativeTo baseURL: URL) throws -> URL
    func body() throws -> Data?
    func transformResponse<T: Decodable>(_ response: HTTPResponse) throws -> T
}

/// Uses the data from an object conforming to `HTTPEndpoint ` to build a URL request.
extension HTTPEndpoint {
    func buildRequest(baseURL: URL) throws -> URLRequest {
        let url = try self.url(relativeTo: baseURL)

        var request = URLRequest(url: url)

        request.httpMethod = self.method.rawValue
        request.allHTTPHeaderFields = try self.headers()
        request.httpBody = try self.body()

        return request
    }
}
