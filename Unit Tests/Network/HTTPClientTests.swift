//
//  HTTPClientTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 5/19/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class HTTPClientTests: XCTestCase {
    func testProcessSuccess() throws {
        let data = Data()
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 222, httpVersion: "1.1", headerFields: [:])

        let httpResult = try HTTPClient<ApptentiveV9API>.processResult(data: data, response: response, error: nil)

        XCTAssertEqual(httpResult.0, data)
        XCTAssertEqual(httpResult.1, response)
    }

    struct MockError: Error {}

    func testProcessConnectionError() throws {
        let error = MockError()

        let result = Result { try HTTPClient<ApptentiveV9API>.processResult(data: nil, response: nil, error: error) }

        if case .failure(let resultingError) = result {
            if case HTTPClientError.connectionError(let underlyingError) = resultingError {
                XCTAssert(underlyingError is MockError)
            } else {
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }

    func testProcessClientError() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 444, httpVersion: "1.1", headerFields: [:])

        let result = Result { try HTTPClient<ApptentiveV9API>.processResult(data: nil, response: response, error: nil) }

        if case .failure(let resultingError) = result {
            if case HTTPClientError.clientError(let errorResponse, let data) = resultingError {
                XCTAssertNil(data)
                XCTAssertEqual(errorResponse, response)
            }
        } else {
            XCTFail()
        }
    }

    func testProcessServerError() throws {
        let url = URL(string: "https://example.com")!
        let response = HTTPURLResponse(url: url, statusCode: 555, httpVersion: "1.1", headerFields: [:])

        let result = Result { try HTTPClient<ApptentiveV9API>.processResult(data: nil, response: response, error: nil) }

        if case .failure(let resultingError) = result {
            if case HTTPClientError.serverError(let errorResponse, let data) = resultingError {
                XCTAssertNil(data)
                XCTAssertEqual(errorResponse, response)
            }
        } else {
            XCTFail()
        }
    }
}
