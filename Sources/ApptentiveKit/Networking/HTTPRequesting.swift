//
//  HTTPRequesting.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Describes the methods needed for an `HTTPClient` object to perform an HTTP request.
protocol HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPCancellable

    func download(_ url: URL, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> HTTPCancellable
}

/// An extension on `URLSession` that allows it to conform to `HTTPRequesting`.
extension URLSession: HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPCancellable {
        let task = self.dataTask(with: request, completionHandler: completion)

        task.resume()

        return URLSessionTaskCancellable(task: task)
    }

    func download(_ url: URL, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> HTTPCancellable {
        let task = self.downloadTask(with: url, completionHandler: completion)

        task.resume()

        return URLSessionTaskCancellable(task: task)
    }
}

/// A protocol describing an HTTP request that can be cancelled.
protocol HTTPCancellable {
    mutating func cancel()
}

/// An implementation of the `HTTPCancellable` protocol using a `URLSessionTask`.
struct URLSessionTaskCancellable: HTTPCancellable {
    var task: URLSessionTask

    func cancel() {
        task.cancel()
    }
}
