//
//  v9ClientTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class v9ClientTests: XCTestCase {

    func testBuildHeaders() {
        let credentials = Apptentive.AppCredentials(key: "123", signature: "abc")
        let headers = V9Client.buildHeaders(credentials: credentials, userAgent: "Apptentive/1.2.3 (Apple)", contentType: "application/json")

        let expectedHeaders = [
            "APPTENTIVE-KEY": "123",
            "APPTENTIVE-SIGNATURE": "abc",
            "X-API-Version": "9",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "application/json",
        ]

        XCTAssertEqual(headers, expectedHeaders)
    }

    func testBuildRequest() {
        let url = URL(string: "https://example.com")!
        let headers = ["Foo": "Bar"]
        let method = "BAZ"

        let request = V9Client.buildRequest(url: url, method: method, headers: headers)

        XCTAssertEqual(request.url, url)
        XCTAssertEqual(request.allHTTPHeaderFields, headers)
        XCTAssertEqual(request.httpMethod, method)
    }

    func testBuildUserAgent() {
        let userAgent = V9Client.buildUserAgent(platform: MockPlatform())

        XCTAssertEqual(userAgent, "Apptentive/1.2.3 (Apple)")
    }

    func testMaps201ResponseToSuccess() {
        guard let response = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 201, httpVersion: nil, headerFields: nil) else {
            return XCTFail("Unable to create HTTPURLResponse")
        }

        let data = """
            {"token": "abc123", "id": "def456", "person_id": "ghi789", "device_id": "jkl012"}
            """.data(using: .utf8)!

        let httpResult = HTTPResult.success((data, response))

        let transformer = { data in
            Result { try JSONDecoder().decode(ConversationResponse.self, from: data) }
        }

        let result = V9Client.transformResult(httpResult, transformer: transformer)

        XCTAssertEqual(try result.get().token, "abc123")
        XCTAssertEqual(try result.get().identifier, "def456")
        XCTAssertEqual(try result.get().personIdentifier, "ghi789")
        XCTAssertEqual(try result.get().deviceIdentifier, "jkl012")
    }

    func testMapsNoResponseToFailure() {
        let transformer = { data in
            Result { try JSONDecoder().decode(ConversationResponse.self, from: data) }
        }

        struct MockError: Error {}
        let result: Result<ConversationResponse, Error> = V9Client.transformResult(HTTPResult.failure(HTTPRequestError.connectionError(MockError())), transformer: transformer)

        XCTAssertThrowsError(try result.get())
    }

    func testAuthenticate() {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor()

        let credentials = Apptentive.AppCredentials(key: "", signature: "")
        let authenticator = V9Client(url: baseURL, appCredentials: credentials, requestor: requestor, platform: MockPlatform())

        let expectation = XCTestExpectation()
        authenticator.createConversation { (success) in

            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            XCTAssert(success || !success)

            expectation.fulfill()
        }

        class SpyRequestor: HTTPRequesting {
            var request: URLRequest?

            func sendRequest(_ request: URLRequest, completion: @escaping (HTTPResult) -> Void) {
                self.request = request

                let stubReponse = HTTPURLResponse()
                completion(.success((Data(), stubReponse)))
            }
        }
    }

    class MockPlatform: PlatformProtocol {
        var sdkVersion: Version {
            "1.2.3"
        }

        var osName: String {
            "fooOS"
        }

        static var current: PlatformProtocol {
            MockPlatform()
        }
    }
}
