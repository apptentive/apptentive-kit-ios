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
    var requestRetrier: HTTPRequestRetrier<ApptentiveV9API>!
    var requestor: SpyRequestor!

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
        let client = HTTPClient<ApptentiveV9API>(requestor: self.requestor, baseURL: URL(string: "https://www.example.com")!)
        self.requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
    }

    func testStart() {
        var conversation = Conversation(environment: MockEnvironment())
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc123", signature: "def456")
        let endpoint: ApptentiveV9API = .createConversation(conversation)

        let expect = self.expectation(description: "create conversation")

        self.requestRetrier.start(endpoint, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(_):
                break

            case .failure(let error):
                XCTFail("conversation creation should succeed. Error: \(error.localizedDescription)")
            }

            expect.fulfill()
        }

        self.wait(for: [expect], timeout: 10.0)
    }

    func testStartUnlessUnderway() {
        self.requestor.delay = 1.0

        var conversation = Conversation(environment: MockEnvironment())
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc123", signature: "def456")
        let endpoint: ApptentiveV9API = .createConversation(conversation)

        let expect = self.expectation(description: "create conversation")

        self.requestRetrier.startUnlessUnderway(endpoint, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(_):
                break

            case .failure(let error):
                XCTFail("conversation creation should succeed. Error: \(error.localizedDescription)")
            }

            expect.fulfill()
        }

        self.requestRetrier.startUnlessUnderway(endpoint, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            XCTFail("Second request completion handler should not be called.")
        }

        self.wait(for: [expect], timeout: 2.0)
    }

    func testRetryOnConnectionError() {
        var conversation = Conversation(environment: MockEnvironment())
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc123", signature: "def456")
        let endpoint: ApptentiveV9API = .createConversation(conversation)

        let expect1 = self.expectation(description: "create conversation")
        let expect2 = self.expectation(description: "retry once")

        self.requestor.error = .connectionError(FakeError())
        self.requestor.extraCompletion = {
            if let _ = self.requestor.error {
                self.requestor.error = nil
                expect2.fulfill()
            }
        }

        self.requestRetrier.start(endpoint, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(_):
                break

            case .failure(let error):
                XCTFail("conversation creation should succeed eventually. Error: \(error.localizedDescription)")
            }

            expect1.fulfill()
        }

        self.wait(for: [expect1, expect2], timeout: 10.0)
    }

    func testNoRetryOnClientError() {
        var conversation = Conversation(environment: MockEnvironment())
        conversation.appCredentials = Apptentive.AppCredentials(key: "abc123", signature: "def456")
        let endpoint: ApptentiveV9API = .createConversation(conversation)

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

        self.requestRetrier.start(endpoint, identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .failure(let error as HTTPClientError):
                switch error {
                case .clientError(_, _):
                    break

                default:
                    XCTFail("Error should be a client error")
                }

            default:
                XCTFail("conversation creation should fail on client error")
            }

            expect1.fulfill()
        }

        self.wait(for: [expect1, expect2], timeout: 10.0)
    }

    struct FakeError: Error {}
}
