//
//  HTTPRequesting.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/24/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPCancellable
}

extension URLSession: HTTPRequesting {
    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPCancellable {
        let task = self.dataTask(with: request, completionHandler: completion)

        task.resume()

        return URLSessionTaskCancellable(task: task)
    }
}

protocol HTTPCancellable {
    func cancel()
}

struct URLSessionTaskCancellable: HTTPCancellable {
    var task: URLSessionTask

    func cancel() {
        task.cancel()
    }
}
