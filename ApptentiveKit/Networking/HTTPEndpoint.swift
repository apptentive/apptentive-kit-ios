//
//  HTTPEndpoint.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/12/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol HTTPEndpoint {
    var method: String { get }

    func headers() throws -> [String: String]
    func url(relativeTo baseURL: URL) throws -> URL
    func body() throws -> Data?
    static func transformResponseData<T: Decodable>(_ data: Data) throws -> T
}

extension HTTPEndpoint {
    func buildRequest(baseURL: URL) throws -> URLRequest {
        let url = try self.url(relativeTo: baseURL)

        var request = URLRequest(url: url)

        request.httpMethod = self.method
        request.allHTTPHeaderFields = try self.headers()
        request.httpBody = try self.body()

        return request
    }
}
