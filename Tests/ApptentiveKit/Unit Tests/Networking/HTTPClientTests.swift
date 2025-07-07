//
//  HTTPClientTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct HTTPClientTests {
    @Test func testProcessSuccess() throws {
        let data = Data()
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 222, httpVersion: "1.1", headerFields: [:])

        let httpResult = try HTTPClient.processResult(data: data, response: response)

        #expect(httpResult.0 == data)
        #expect(httpResult.1 == response)
    }

    @Test func testProcessClientError() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 444, httpVersion: "1.1", headerFields: [:])

        let result = Result { try HTTPClient.processResult(data: nil, response: response) }

        if case .failure(let resultingError) = result {
            if case HTTPClientError.clientError(let errorResponse, let data) = resultingError {
                #expect(data == nil)
                #expect(errorResponse == response)
            }
        } else {
            Issue.record("Expected client error to register as a failure")
        }
    }

    @Test func testProcessServerError() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 555, httpVersion: "1.1", headerFields: [:])

        let result = Result { try HTTPClient.processResult(data: nil, response: response) }

        if case .failure(let resultingError) = result {
            if case HTTPClientError.serverError(let errorResponse, let data) = resultingError {
                #expect(data == nil)
                #expect(errorResponse == response)
            }
        } else {
            Issue.record("Expected client error to register as a failure")
        }
    }
}
