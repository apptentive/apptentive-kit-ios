//
//  SpyRequestor.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

@testable import ApptentiveKit

actor SpyRequestor: HTTPRequesting {
    var request: URLRequest?
    var responseData: Data?
    var response: URLResponse?
    var temporaryURL: URL?
    var extraCompletion: (@Sendable (SpyRequestor) -> Void)?
    var delay: TimeInterval = 0
    var error: HTTPClientError?

    init(responseData: Data) {
        self.responseData = responseData
    }

    init(temporaryURL: URL) {
        self.temporaryURL = temporaryURL
    }

    func setTemporaryURL(_ temporaryURL: URL?) {
        self.temporaryURL = temporaryURL
    }

    func setResponseData(_ responseData: Data?) {
        self.responseData = responseData
    }

    func setResponse(_ response: URLResponse?) {
        self.response = response
    }

    func setError(_ error: HTTPClientError?) {
        self.error = error
    }

    func setExtraCompletion(_ extraCompletion: (@Sendable (SpyRequestor) -> Void)?) {
        self.extraCompletion = extraCompletion
    }

    func runInContext(_ closure: (SpyRequestor) -> Void) {
        closure(self)
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        defer {
            self.extraCompletion?(self)
        }

        self.request = request

        try await Task.sleep(nanoseconds: UInt64(self.delay) * NSEC_PER_SEC)

        if let error = self.error {
            throw error
        } else if let response = self.response, let responseData = self.responseData {
            return (responseData, response)
        } else {
            throw ApptentiveError.internalInconsistency
        }
    }

    func download(from url: URL, delegate: (any URLSessionTaskDelegate)?) async throws -> (URL, URLResponse) {
        defer {
            self.extraCompletion?(self)
        }

        try await Task.sleep(nanoseconds: UInt64(self.delay) * NSEC_PER_SEC)

        if let error = self.error {
            throw error
        } else if let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "1.1", headerFields: [:]), let temporaryURL = self.temporaryURL {
            return (temporaryURL, response)
        } else {
            throw ApptentiveError.internalInconsistency
        }
    }
}
