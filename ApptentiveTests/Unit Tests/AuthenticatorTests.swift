//
//  AuthenticatorTests.swift
//  ApptentiveTests
//
//  Created by Apptentive on 2/21/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import XCTest
@testable import Apptentive


class AuthenticatorTests: XCTestCase {

	func testBuildHeaders() {
		let credentials = Apptentive.Credentials(key: "123", signature: "abc")
		let expectedHeaders = [
			ApptentiveAuthenticator.Headers.apptentiveKey: "123",
			ApptentiveAuthenticator.Headers.apptentiveSignature: "abc"
		]

		let headers = ApptentiveAuthenticator.buildHeaders(credentials: credentials)

		XCTAssertEqual(headers, expectedHeaders)
	}

	func testBuildsARequest() {
		let url = URL(string: "https://example.com")!
		let headers = ["Foo": "Bar"]
		let method = "BAZ"

		let request = ApptentiveAuthenticator.buildRequest(url: url, method: method, headers: headers)

		XCTAssertEqual(request.url, url)
		XCTAssertEqual(request.allHTTPHeaderFields, headers)
		XCTAssertEqual(request.httpMethod, method)
	}

	func testMaps200ResponseToSuccess() {
		let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)

		let result = ApptentiveAuthenticator.processResponse(response: response)

		XCTAssertTrue(result)
	}

	func testMapsNoResponseToFailure() {
		let response: URLResponse? = nil

		let result = ApptentiveAuthenticator.processResponse(response: response)

		XCTAssertFalse(result)
	}

	func testAuthenticate() {
        let url = URL(string: "http://example.com")!
		let requestor = SpyRequestor()
        
        let authenticator = ApptentiveAuthenticator(url: url, requestor: requestor)
		let credentials = Apptentive.Credentials(key: "", signature: "")

		let expectation = XCTestExpectation()
		authenticator.authenticate(credentials: credentials) { (success) in

			XCTAssertNotNil(requestor.request)
			XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, url)
			XCTAssertEqual(requestor.request?.httpMethod, "POST")
			XCTAssert(success || !success)

			expectation.fulfill()
		}

        class SpyRequestor: HTTPRequesting {
            var request: URLRequest?

            func sendRequest(_ request: URLRequest, completion: @escaping (URLResult) -> ()) {
                self.request = request

                let stubReponse = HTTPURLResponse()
                completion((nil, stubReponse, nil))
            }
        }
	}
}
