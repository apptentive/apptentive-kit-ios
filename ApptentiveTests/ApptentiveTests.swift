//
//  ApptentiveTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/18/20.
//  Copyright © 2020 Frank Schmitt. All rights reserved.
//

import Nimble
import Quick
import Apptentive

class Authentication: QuickSpec {
	override func spec() {

		describe("Apptentive authentication") {
			it("authenticates successfully with valid credentials") {

				let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 201, httpVersion: nil, headerFields: nil)
				let sessionWrapper = MockSessionWrapper(data: Data(), response: response, error: nil)

				let apptentive = Apptentive(sessionWrapper: sessionWrapper)

				waitUntil { done in
					apptentive.register(credentials: Apptentive.Credentials(key: "abc", signature: "123")) { (error) in
						expect(error).to(beNil())
						done()
					}
				}
			}
		}
	}
}

class MockSessionWrapper: SessionWrapper {
	let data: Data?
	let response: URLResponse?
	let error: Error?

	init(data: Data?, response: URLResponse?, error: Error?) {
		self.data = data
		self.response = response
		self.error = error
	}

	func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
		completion(self.data, self.response, self.error)
	}
}

