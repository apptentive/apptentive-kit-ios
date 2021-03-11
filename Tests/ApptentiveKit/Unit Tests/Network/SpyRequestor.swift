//
//  SpyRequestor.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@testable import ApptentiveKit

class SpyRequestor: HTTPRequesting {
    var request: URLRequest?
    var responseData: Data
    var extraCompletion: (() -> Void)?
    var delay: TimeInterval = 0
    var error: HTTPClientError?

    init(responseData: Data) {
        self.responseData = responseData
    }

    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPCancellable {
        self.request = request

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(self.delay / 1000.0))) {
            switch self.error {
            case .clientError(let response, _):
                completion(self.responseData, response, nil)

            case .serverError(let response, _):
                completion(self.responseData, response, nil)

            case .none:
                let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "1.1", headerFields: [:])
                completion(self.responseData, response, nil)

            default:
                completion(self.responseData, nil, self.error)
            }

            self.extraCompletion?()
        }

        return FakeHTTPCancellable()
    }
}

struct FakeHTTPCancellable: HTTPCancellable {
    var didCancel: Bool = false
    mutating func cancel() {
        self.didCancel = true
    }
}
