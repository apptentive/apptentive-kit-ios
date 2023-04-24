//
//  HTTPRequestRetrierTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class HTTPRequestRetrierTests: XCTestCase {
    var requestRetrier: HTTPRequestRetrier!
    var requestor: SpyRequestor!
    let pendingCredentials = PendingAPICredentials(appCredentials: .init(key: "abc", signature: "123"))

    override func setUp() {
        let responseString = """
            {
            "token": "abc123",
            "id": "def456",
            "person_id": "ghi789",
            "device_id": "jkl012"
            }
            """

        self.requestor = SpyRequestor(responseData: responseString.data(using: .utf8)!)

        let retryPolicy = HTTPRetryPolicy(initialDelay: 1.0, multiplier: 1.0, useJitter: false)
        let client = HTTPClient(requestor: self.requestor, baseURL: URL(string: "https://www.example.com")!, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        self.requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
    }

    func testStart() {
        let conversation = Conversation(environment: MockEnvironment())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        let expect = self.expectation(description: "create conversation")

        self.requestRetrier.start(builder, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(_):
                break

            case .failure(let error):
                XCTFail("conversation creation should succeed. Error: \(error.localizedDescription)")
            }

            expect.fulfill()
        }

        self.wait(for: [expect], timeout: 5)
    }

    func testStartUnlessUnderway() {
        self.requestor.delay = 1.0

        let conversation = Conversation(environment: MockEnvironment())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        let expect = self.expectation(description: "create conversation")

        self.requestRetrier.startUnlessUnderway(builder, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(_):
                break

            case .failure(let error):
                XCTFail("conversation creation should succeed. Error: \(error.localizedDescription)")
            }

            expect.fulfill()
        }

        self.requestRetrier.startUnlessUnderway(builder, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            XCTFail("Second request completion handler should not be called.")
        }

        self.wait(for: [expect], timeout: 5)
    }

    func testRetryOnConnectionError() {
        let conversation = Conversation(environment: MockEnvironment())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        let expect1 = self.expectation(description: "create conversation")
        let expect2 = self.expectation(description: "retry once")

        self.requestor.error = .connectionError(FakeError())
        self.requestor.extraCompletion = {
            if let _ = self.requestor.error {
                self.requestor.error = nil
                expect2.fulfill()
            }
        }

        self.requestRetrier.start(builder, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(_):
                break

            case .failure(let error):
                XCTFail("conversation creation should succeed eventually. Error: \(error.localizedDescription)")
            }

            expect1.fulfill()
        }

        self.wait(for: [expect1, expect2], timeout: 5)
    }

    func testNoRetryOnClientError() {
        let conversation = Conversation(environment: MockEnvironment())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        let expect1 = self.expectation(description: "create conversation")
        let expect2 = self.expectation(description: "retry once")

        let errorResponse = HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 403, httpVersion: "1.1", headerFields: [:])!

        self.requestor.error = .clientError(errorResponse, nil)

        self.requestor.extraCompletion = {
            if let _ = self.requestor.error {
                self.requestor.error = nil
                expect2.fulfill()
            } else {
                XCTFail("Should not retry request on client error")
            }
        }

        self.requestRetrier.start(builder, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .failure(let error as HTTPClientError):
                switch error {
                case .clientError(_, _):
                    break

                default:
                    XCTFail("Error should be a client or unauthorized error")
                }

            default:
                XCTFail("conversation creation should fail on client error")
            }

            expect1.fulfill()
        }

        self.wait(for: [expect1, expect2], timeout: 5)
    }

    func testNoRetryOnUnauthorizedError() {
        let conversation = Conversation(environment: MockEnvironment())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        let expect1 = self.expectation(description: "create conversation")
        let expect2 = self.expectation(description: "retry once")

        let errorResponse = HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 401, httpVersion: "1.1", headerFields: [:])!

        self.requestor.error = .clientError(errorResponse, nil)

        self.requestor.extraCompletion = {
            if let _ = self.requestor.error {
                self.requestor.error = nil
                expect2.fulfill()
            } else {
                XCTFail("Should not retry request on client error")
            }
        }

        self.requestRetrier.start(builder, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .failure(let error as HTTPClientError):
                switch error {
                case .unauthorized(_, _):
                    break

                default:
                    XCTFail("Error should be a client or unauthorized error")
                }

            default:
                XCTFail("conversation creation should fail on client error")
            }

            expect1.fulfill()
        }

        self.wait(for: [expect1, expect2], timeout: 5)
    }

    struct FakeError: Error {}
}
