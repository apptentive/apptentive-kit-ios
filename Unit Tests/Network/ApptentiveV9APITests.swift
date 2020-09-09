//
//  ApptentiveV9APITests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class ApptentiveV9APITests: XCTestCase {
    func testBuildHeaders() {
        let appCredentials = Apptentive.AppCredentials(key: "123", signature: "abc")

        let headers = ApptentiveV9API.buildHeaders(
            appCredentials: appCredentials,
            userAgent: "Apptentive/1.2.3 (Apple)",
            contentType: "foo/bar",
            apiVersion: "9")

        let expectedHeaders = [
            "APPTENTIVE-KEY": "123",
            "APPTENTIVE-SIGNATURE": "abc",
            "X-API-Version": "9",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "foo/bar",
        ]

        XCTAssertEqual(headers, expectedHeaders)
    }

    func testBuildRequest() throws {
        let path = "foo"
        let method = "BAZ"
        let bodyObject = MockEncodable(foo: "foo", bar: "bar")
        let baseURL = URL(string: "https://api.example.com/")!
        var conversation = Conversation(environment: Environment())
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc", signature: "123")
        conversation.appRelease.sdkVersion = "1.2.3"

        let endpoint = ApptentiveV9API(conversation: conversation, path: path, method: method, bodyObject: ApptentiveV9API.HTTPBodyEncodable(value: bodyObject))

        let request = try endpoint.buildRequest(baseURL: baseURL)

        let expectedHeaders = [
            "APPTENTIVE-KEY": "abc",
            "APPTENTIVE-SIGNATURE": "123",
            "X-API-Version": "9",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "application/json",
        ]

        XCTAssertEqual(request.url, URL(string: "https://api.example.com/foo")!)
        XCTAssertEqual(request.httpMethod, method)
        XCTAssertEqual(request.allHTTPHeaderFields, expectedHeaders)
    }

    func testBuildUserAgent() {
        let userAgent = ApptentiveV9API.userAgent(sdkVersion: "1.2.3")

        XCTAssertEqual(userAgent, "Apptentive/1.2.3 (Apple)")
    }

    func testAuthenticate() throws {
        let baseURL = URL(string: "http://example.com")!
        var conversation = Conversation(environment: Environment())
        let requestor = SpyRequestor(responseData: try JSONEncoder().encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789")))
        let credentials = Apptentive.AppCredentials(key: "abc", signature: "123")
        conversation.appRelease.sdkVersion = "1.2.3"
        conversation.appCredentials = credentials

        let client = HTTPClient<ApptentiveV9API>(requestor: requestor, baseURL: baseURL)

        let expectation = XCTestExpectation()
        let _ = client.request(.createConversation(conversation)) { (result: Result<ConversationResponse, Error>) in
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Error (fake) creating conversation: \(error)")
            }

            expectation.fulfill()
        }

        class SpyRequestor: HTTPRequesting {
            var request: URLRequest?
            var responseData: Data

            init(responseData: Data) {
                self.responseData = responseData
            }

            func sendRequest(_ request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPCancellable {
                self.request = request

                let stubReponse = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: "1.1", headerFields: [:])
                completion(responseData, stubReponse, nil)

                return FakeHTTPCancellable()
            }
        }
    }

    struct MockEncodable: Encodable {
        let foo: String
        let bar: String
    }

    struct FakeHTTPCancellable: HTTPCancellable {
        func cancel() {}
    }
}
