//
//  SpyRequestor.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@testable import ApptentiveKit

class SpyRequestor: HTTPRequesting, FakeHTTPCancellableDelegate {
    var request: URLRequest?
    var responseData: Data?
    var temporaryURL: URL?
    var extraCompletion: (() -> Void)?
    var delay: TimeInterval = 0
    var error: HTTPClientError?
    var cancellable: FakeHTTPCancellable?
    var maxAge: Int = 0

    init(responseData: Data) {
        self.responseData = responseData
    }

    init(temporaryURL: URL) {
        self.temporaryURL = temporaryURL
    }

    func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPCancellable {
        self.request = request

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(self.delay / 1000.0))) {
            switch self.error {
            case .clientError(let response, _):
                completion(self.responseData, response, nil)

            case .unauthorized(let response, _):
                completion(self.responseData, response, nil)

            case .serverError(let response, _):
                completion(self.responseData, response, nil)

            case .none:
                var headerFields = [String: String]()
                if self.maxAge > 0 {
                    headerFields["Cache-Control"] = "max-age=\(self.maxAge)"
                }

                let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "1.1", headerFields: headerFields)
                completion(self.responseData, response, nil)

            default:
                completion(nil, nil, self.error)
            }

            self.extraCompletion?()
        }

        self.cancellable = FakeHTTPCancellable()
        self.cancellable?.delegate = self

        return self.cancellable!
    }

    func download(_ url: URL, completion: @escaping (URL?, URLResponse?, Error?) -> Void) -> HTTPCancellable {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(self.delay / 1000.0))) {
            switch self.error {
            case .clientError(let response, _):
                completion(self.temporaryURL, response, self.error)

            case .serverError(let response, _):
                completion(self.temporaryURL, response, self.error)

            case .none:
                let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: [:])
                completion(self.temporaryURL, response, nil)

            default:
                completion(nil, nil, self.error)
            }

            self.extraCompletion?()
        }

        self.cancellable = FakeHTTPCancellable()
        self.cancellable?.delegate = self

        return self.cancellable!
    }

    func didCancel(_ cancellable: FakeHTTPCancellable) {
        self.error = .connectionError(URLError(.cancelled))
    }

    func clearCache(for request: URLRequest) {
    }
}

protocol FakeHTTPCancellableDelegate: AnyObject {
    func didCancel(_ cancellable: FakeHTTPCancellable)
}

class FakeHTTPCancellable: NSObject, HTTPCancellable {
    var didCancel: Bool = false
    weak var delegate: FakeHTTPCancellableDelegate?

    func cancel() {
        self.didCancel = true
        self.delegate?.didCancel(self)
    }
}
