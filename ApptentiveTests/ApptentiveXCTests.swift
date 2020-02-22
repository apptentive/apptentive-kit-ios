//
//  ApptentiveXCTests.swift
//  ApptentiveTests
//
//  Created by Apptentive on 2/21/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import Foundation
import XCTest
@testable import Apptentive

class AuthenticationFeatureTest: XCTestCase {
    
	struct MockAuthenticator: Authenticating {

        let shouldSucceed: Bool

		func authenticate(credentials: Apptentive.Credentials, completion: @escaping (Bool) -> ()) {
			completion(self.shouldSucceed)
		}
    }
    
    func testSDKRegistrationSucceedsWithPositiveConfirmation() {
        
        self.sdkRegistrationWithConfirmation(shouldSucceed: true) {
            XCTAssertTrue($0)
        }
    }
    
    func testSDKRegistrationFailsWithNegativeConfirmation() {
        
        self.sdkRegistrationWithConfirmation(shouldSucceed: false) {
            XCTAssertFalse($0)
        }
    }
    
    func sdkRegistrationWithConfirmation(shouldSucceed: Bool, asserts: @escaping (Bool)->()) {

        let authenticator = MockAuthenticator(shouldSucceed: shouldSucceed)
        
        let expectation = XCTestExpectation()

		let credentials = Apptentive.Credentials(key: "", signature: "")

		Apptentive(authenticator: authenticator).register(credentials: credentials) { success in
            asserts(success)
            expectation.fulfill()
        }
    }
}

class AuthenticatorTests: XCTestCase {
	func testBuildHeaders() {
		let credentials = Apptentive.Credentials(key: "123", signature: "abc")
		let expectedHeaders = [
			"APPTENTIVE-KEY": "123",
			"APPTENTIVE-SIGNATURE": "abc"
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

	func testMaps201ResponseToSuccess() {
		let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 201, httpVersion: nil, headerFields: nil)

		let result = ApptentiveAuthenticator.processResponse(response: response)

		XCTAssertTrue(result)
	}

	func testMaps401ResponseToFailure() {
		let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 401, httpVersion: nil, headerFields: nil)

		let result = ApptentiveAuthenticator.processResponse(response: response)

		XCTAssertFalse(result)
	}

	func testMapsNoResponseToFailure() {
		let response: URLResponse? = nil

		let result = ApptentiveAuthenticator.processResponse(response: response)

		XCTAssertFalse(result)
	}

	func testAuthenticate() {
		let requestor = SpyRequestor()
		let authenticator = ApptentiveAuthenticator(requestor: requestor)
		let credentials = Apptentive.Credentials(key: "", signature: "")

		let expectation = XCTestExpectation()
		authenticator.authenticate(credentials: credentials) { (success) in

			XCTAssertNotNil(requestor.request)
			XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
			XCTAssertNotNil(requestor.request?.url)
			XCTAssertEqual(requestor.request?.httpMethod?.isEmpty, false)
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
