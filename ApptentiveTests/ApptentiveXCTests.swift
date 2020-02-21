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
        
        func authenticate(key: String, signature: String, completion: @escaping (Bool) -> ()) {
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
        
        Apptentive(authenticator: authenticator).register(key: "", signature: "") { success in
            asserts(success)
            expectation.fulfill()
        }
    }
}

class AuthenticatorTests: XCTestCase {
	func testBuildsARequest() {
		let expectedURL = URL(string: "https://example.com")!

		let request = ApptentiveAuthenticator.buildRequest(key: "", signature: "", url: expectedURL)

		XCTAssertNotNil(request.url)
		XCTAssertEqual(false, request.allHTTPHeaderFields?.isEmpty)
		XCTAssertEqual(false, request.httpMethod?.isEmpty)
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

		let expectation = XCTestExpectation()
		authenticator.authenticate(key: "", signature: "") { (success) in

			XCTAssertNotNil(requestor.request)
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
