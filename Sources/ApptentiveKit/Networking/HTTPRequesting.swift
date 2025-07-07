//
//  HTTPRequesting.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes the methods needed for an `HTTPClient` object to perform an HTTP request.
protocol HTTPRequesting: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)

    func download(from url: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse)
}

/// An extension on `URLSession` that allows it to conform to `HTTPRequesting`.
extension URLSession: HTTPRequesting {}
