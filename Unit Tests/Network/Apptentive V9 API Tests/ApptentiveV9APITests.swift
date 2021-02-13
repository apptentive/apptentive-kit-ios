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
            contentType: "foo/bar",
            accept: "foo/bar",
            acceptCharset: "utf-123",
            acceptLanguage: "en",
            apiVersion: "9",
            token: "foobar"
            )

        let expectedHeaders = [
            "APPTENTIVE-KEY": "123",
            "APPTENTIVE-SIGNATURE": "abc",
            "X-API-Version": "9",
            "Content-Type": "foo/bar",
            "Authorization": "Bearer foobar",
            "Accept": "foo/bar",
            "Accept-Charset": "utf-123",
            "Accept-Language": "en"
        ]

        XCTAssertEqual(headers, expectedHeaders)
    }

    func testBuildRequest() throws {
        let path = "foo"
        let method = HTTPMethod.delete
        let bodyObject = MockEncodable(foo: "foo", bar: "bar")
        let baseURL = URL(string: "https://api.example.com/")!
        var conversation = Conversation(environment: Environment())
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc", signature: "123")
        conversation.conversationCredentials = Conversation.ConversationCredentials(token: "def", id: "456")

        let endpoint = ApptentiveV9API(credentials: conversation, path: path, method: method, bodyObject: ApptentiveV9API.HTTPBodyEncodable(value: bodyObject))

        let request = try endpoint.buildRequest(baseURL: baseURL, userAgent: "Apptentive/1.2.3 (Apple)")

        let expectedHeaders = [
            "APPTENTIVE-KEY": "abc",
            "APPTENTIVE-SIGNATURE": "123",
            "X-API-Version": "9",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "application/json",
            "Authorization": "Bearer def",
            "Accept": "application/json",
            "Accept-Charset": "UTF-8",
            "Accept-Language": "en"
        ]

        XCTAssertEqual(request.url, URL(string: "https://api.example.com/conversations/456/foo")!)
        XCTAssertEqual(request.httpMethod, method.rawValue)
        XCTAssertEqual(request.allHTTPHeaderFields, expectedHeaders)
    }

    func testBuildUserAgent() {
        let userAgent = ApptentiveV9API.userAgent(sdkVersion: "1.2.3")

        XCTAssertEqual(userAgent, "Apptentive/1.2.3 (Apple)")
    }

    func testParseExpiry() {
        let response1 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Cache-Control": "max-age = 86400"])!

        guard let expiry1 = ApptentiveV9API.parseExpiry(response1) else {
            return XCTFail("Unable to parse valid expiry")
        }

        XCTAssertEqual(expiry1.timeIntervalSinceNow, Date(timeIntervalSinceNow: 86400).timeIntervalSinceNow, accuracy: 1.0)

        let response2 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Cache-control": "axmay-agehay: 86400"])!

        let expiry2 = ApptentiveV9API.parseExpiry(response2)

        XCTAssertNil(expiry2)

        XCTAssertEqual(expiry1.timeIntervalSinceNow, Date(timeIntervalSinceNow: 86400).timeIntervalSinceNow, accuracy: 1.0)

        let response3 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["cAcHe-cOnTrOl": "max-age = 200"])!

        guard let expiry3 = ApptentiveV9API.parseExpiry(response3) else {
            return XCTFail("Unable to parse valid expiry (with weird case)")
        }

        XCTAssertEqual(expiry3.timeIntervalSinceNow, Date(timeIntervalSinceNow: 200).timeIntervalSinceNow, accuracy: 1.0)
    }

    func testCreateConversation() throws {
        let baseURL = URL(string: "http://example.com")!
        var conversation = Conversation(environment: Environment())
        let requestor = SpyRequestor(responseData: try JSONEncoder().encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789")))
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc", signature: "123")

        let client = HTTPClient<ApptentiveV9API>(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveV9API.userAgent(sdkVersion: "1.2.3"))

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
    }

    func testCreateSurveyResponse() throws {
        let baseURL = URL(string: "http://example.com")!
        var conversation = Conversation(environment: Environment())
        let requestor = SpyRequestor(responseData: Data())
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc", signature: "123")
        conversation.conversationCredentials = Conversation.ConversationCredentials(token: "456", id: "def")

        let client = HTTPClient<ApptentiveV9API>(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveV9API.userAgent(sdkVersion: "1.2.3"))
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier)

        let surveyResponse = SurveyResponse(surveyID: "789", answers: ["1": [SurveyQuestionResponse.freeform("foo")]])

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/surveys/789/responses"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            expectation.fulfill()
        }

        payloadSender.send(Payload(wrapping: surveyResponse), for: conversation)
    }

    func testCreateEvent() throws {
        let baseURL = URL(string: "http://example.com")!
        var conversation = Conversation(environment: Environment())
        let requestor = SpyRequestor(responseData: Data())
        conversation.appRelease.sdkVersion = "1.2.3"
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc", signature: "123")
        conversation.conversationCredentials = Conversation.ConversationCredentials(token: "456", id: "def")

        let client = HTTPClient<ApptentiveV9API>(requestor: requestor, baseURL: baseURL, userAgent: "foo")
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier)

        let event = Event(name: "Foobar")

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/events"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            expectation.fulfill()
        }

        payloadSender.send(Payload(wrapping: event), for: conversation)
    }

    struct MockEncodable: Encodable {
        let foo: String
        let bar: String
    }
}
