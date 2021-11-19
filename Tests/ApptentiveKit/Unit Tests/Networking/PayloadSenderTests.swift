//
//  PayloadSenderTests.swift
//  PayloadSenderTests
//
//  Created by Frank Schmitt on 9/2/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class PayloadSenderTests: XCTestCase {
    var requestRetrier = SpyRequestStarter()
    var saver = SpySaver(containerURL: URL(string: "file:///tmp")!, filename: "PayloadQueue", fileManager: FileManager.default)
    var payloadSender: PayloadSender!
    var credentialsProvider = MockCredentialsProvider(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), conversationCredentials: Conversation.ConversationCredentials(token: "def", id: "456"), acceptLanguage: "en")

    override func setUp() {
        self.payloadSender = PayloadSender(requestRetrier: self.requestRetrier)
    }

    func testNormalOperation() throws {
        self.payloadSender.saver = self.saver

        self.payloadSender.send(Payload(wrapping: "test1"))
        self.payloadSender.send(Payload(wrapping: "test2"))
        self.payloadSender.send(Payload(wrapping: "test3"))

        // Payload sender should not save queue to saver by default.
        XCTAssertEqual(self.saver.payloads.count, 0)

        try self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        XCTAssertEqual(self.saver.payloads.count, 3)

        // Mock the payload send request to succeed.
        self.requestRetrier.result = .success(PayloadResponse())

        // Start the payload sending process by setting the credentials.
        payloadSender.credentialsProvider = self.credentialsProvider

        // Send one straggler payload while the requests are running.
        self.payloadSender.send(Payload(wrapping: "test4"))

        let expectation = XCTestExpectation(description: "PayloadSender sends payloads")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            do {
                try self.payloadSender.savePayloadsIfNeeded()

                // Payload queue should be empty
                XCTAssertEqual(self.saver.payloads.count, 0)

                // Retrier should have made a request.
                XCTAssertEqual(self.requestRetrier.requests.count, 4)
            } catch let error {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testHTTPClientError() throws {
        self.payloadSender.saver = self.saver

        self.payloadSender.send(Payload(wrapping: "test1"))
        self.payloadSender.send(Payload(wrapping: "test2"))
        self.payloadSender.send(Payload(wrapping: "test3"))

        // Payload sender should not save queue to saver by default.
        XCTAssertEqual(self.saver.payloads.count, 0)

        try self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        XCTAssertEqual(self.saver.payloads.count, 3)

        // Mock the payload send request to fail.
        self.requestRetrier.result = .failure(HTTPClientError.clientError(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations/1234/events")!, statusCode: 422, httpVersion: nil, headerFields: nil)!, nil))

        // Start the payload sending process by setting the credentials.
        payloadSender.credentialsProvider = self.credentialsProvider

        // Send one straggler payload while the requests are running.
        self.payloadSender.send(Payload(wrapping: "test4"))

        let expectation = XCTestExpectation(description: "PayloadSender sends payloads")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            do {
                try self.payloadSender.savePayloadsIfNeeded()

                // Payload queue should be empty
                XCTAssertEqual(self.saver.payloads.count, 0)

                // Retrier should have made a request.
                XCTAssertEqual(self.requestRetrier.requests.count, 4)
            } catch let error {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testNoDiskAccess() {
        self.payloadSender.send(Payload(wrapping: "test1"))

        // Mock the payload send request to succeed.
        self.requestRetrier.result = .success(PayloadResponse())

        // Start the payload sending process by setting the credentials.
        payloadSender.credentialsProvider = self.credentialsProvider

        // Retrier should have made a request.
        XCTAssertEqual(self.requestRetrier.requests.count, 1)
    }

    func testImportantPayload() {
        self.payloadSender.saver = self.saver

        self.payloadSender.send(Payload(wrapping: "test1"), persistEagerly: true)

        // Payload sender should save queue to saver when `persistEagerly` is set.
        XCTAssertEqual(self.saver.payloads.count, 1)
    }

    func testDrain() throws {
        self.payloadSender.saver = self.saver

        self.payloadSender.send(Payload(wrapping: "test1"))
        self.payloadSender.send(Payload(wrapping: "test2"))
        self.payloadSender.send(Payload(wrapping: "test3"))

        // Payload sender should not save queue to saver by default.
        XCTAssertEqual(self.saver.payloads.count, 0)

        // Mock the payload send request to succeed.
        self.requestRetrier.result = .success(PayloadResponse())

        let expectation = XCTestExpectation(description: "Payload sender finishes draining")

        self.payloadSender.drain {
            XCTAssertEqual(self.requestRetrier.requests.count, 3)

            // Try sending another payload, making sure we'll be suspended.
            DispatchQueue.main.async {
                self.payloadSender.send(Payload(wrapping: "test4"))

                // Payload sender should be suspended and not send the last request.
                XCTAssertEqual(self.requestRetrier.requests.count, 3)

                self.payloadSender.resume()

                XCTAssertEqual(self.requestRetrier.requests.count, 4)

                expectation.fulfill()
            }
        }

        // Start the payload sending process by setting the credentials.
        payloadSender.credentialsProvider = self.credentialsProvider

        self.wait(for: [expectation], timeout: 5)
    }

    class SpyRequestStarter: HTTPRequestStarting {
        var result: Result<PayloadResponse, Error>? = nil
        var requests = [HTTPEndpoint]()

        func start<T>(_ endpoint: HTTPEndpoint, identifier: String, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
            guard let result = self.result as? Result<T, Error> else {
                return XCTFail("Mock object type/nullability mismatch")
            }

            self.requests.append(endpoint)

            // Simulate network delay.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(10)) {
                completion(result)
            }
        }
    }

    class SpySaver: Saver<[Payload]> {
        var payloads = [Payload]()

        override func save(_ object: [Payload]) throws {
            self.payloads = object
        }
    }

    struct MockCredentialsProvider: APICredentialsProviding {
        var appCredentials: Apptentive.AppCredentials?

        var conversationCredentials: Conversation.ConversationCredentials?

        var acceptLanguage: String?
    }
}
