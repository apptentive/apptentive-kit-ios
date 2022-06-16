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
    var notificationCenter = MockNotificationCenter()

    override func setUp() {
        self.payloadSender = PayloadSender(requestRetrier: self.requestRetrier, notificationCenter: self.notificationCenter)
    }

    func testSessionID() throws {
        Payload.context.startSession()

        let payloadWithSession = Payload(wrapping: "test1")

        Payload.context.endSession()

        let payloadWithoutSession = Payload(wrapping: "test2")

        Payload.context.startSession()

        let payloadWithOtherSession = Payload(wrapping: "test3")

        XCTAssertNotNil(payloadWithSession.jsonObject.sessionID)
        XCTAssertNil(payloadWithoutSession.jsonObject.sessionID)
        XCTAssertNotEqual(payloadWithSession.jsonObject.sessionID, payloadWithOtherSession.jsonObject.sessionID)

        let encodedPayload = try JSONEncoder().encode(payloadWithSession)
        let decodedPayload = try JSONDecoder().decode(Payload.self, from: encodedPayload)

        XCTAssertNotNil(decodedPayload.jsonObject.sessionID)
    }

    func testNormalOperation() throws {
        self.payloadSender.saver = self.saver

        let payloads = [
            Payload(wrapping: "test1"),
            Payload(wrapping: "test2"),
            Payload(wrapping: "test3"),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])
        self.payloadSender.send(payloads[2])

        let nonces = payloads.map { $0.jsonObject.nonce }

        XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces)

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
        let straggler = Payload(wrapping: "test4")

        self.payloadSender.send(straggler)

        let expectation = XCTestExpectation(description: "PayloadSender sends payloads")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            XCTAssertEqual(self.notificationCenter.sendingNonces, nonces + [straggler.jsonObject.nonce])

            do {
                try self.payloadSender.savePayloadsIfNeeded()

                // Payload queue should be empty
                XCTAssertEqual(self.saver.payloads.count, 0)

                // Retrier should have made a request.
                XCTAssertEqual(self.requestRetrier.requests.count, 4)

                XCTAssertEqual(self.notificationCenter.sentNonces, nonces + [straggler.jsonObject.nonce])
                XCTAssertEqual(self.notificationCenter.failedNonces, [])
            } catch let error {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testHTTPClientError() throws {
        self.payloadSender.saver = self.saver

        let payloads = [
            Payload(wrapping: "test1"),
            Payload(wrapping: "test2"),
            Payload(wrapping: "test3"),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])
        self.payloadSender.send(payloads[2])

        let nonces = payloads.map { $0.jsonObject.nonce }

        XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces)

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
        let straggler = Payload(wrapping: "test4")

        self.payloadSender.send(straggler)

        let expectation = XCTestExpectation(description: "PayloadSender sends payloads")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            XCTAssertEqual(self.notificationCenter.sendingNonces, nonces + [straggler.jsonObject.nonce])

            do {
                try self.payloadSender.savePayloadsIfNeeded()

                // Payload queue should be empty
                XCTAssertEqual(self.saver.payloads.count, 0)

                XCTAssertEqual(self.notificationCenter.failedNonces, nonces + [straggler.jsonObject.nonce])
                XCTAssertEqual(self.notificationCenter.failedErrors.count, 4)

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

        let payloads = [
            Payload(wrapping: "test1"),
            Payload(wrapping: "test2"),
            Payload(wrapping: "test3"),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])
        self.payloadSender.send(payloads[2])

        let nonces = payloads.map { $0.jsonObject.nonce }

        XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces)

        // Payload sender should not save queue to saver by default.
        XCTAssertEqual(self.saver.payloads.count, 0)

        // Mock the payload send request to succeed.
        self.requestRetrier.result = .success(PayloadResponse())

        let expectation = XCTestExpectation(description: "Payload sender finishes draining")

        self.payloadSender.drain {
            XCTAssertEqual(self.notificationCenter.sendingNonces, nonces)
            XCTAssertEqual(self.notificationCenter.sentNonces, nonces)
            XCTAssertEqual(self.notificationCenter.failedNonces, [])

            XCTAssertEqual(self.requestRetrier.requests.count, 3)

            // Try sending another payload, making sure we'll be suspended.
            DispatchQueue.main.async {
                let straggler = Payload(wrapping: "test4")

                self.payloadSender.send(straggler)

                XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces + [straggler.jsonObject.nonce])
                XCTAssertEqual(self.notificationCenter.sentNonces, nonces)
                XCTAssertEqual(self.notificationCenter.failedNonces, [])

                XCTAssertEqual(self.notificationCenter.sendingNonces, nonces)

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

class MockNotificationCenter: NotificationCenter {
    var postedNotifications = [Notification]()

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        self.postedNotifications.append(Notification(name: aName, object: anObject, userInfo: aUserInfo))
    }
}

extension MockNotificationCenter {
    var enqueuedNonces: [String] {
        postedNotifications.filter { $0.name == .payloadEnqueued }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.jsonObject.nonce }
    }

    var sendingNonces: [String] {
        postedNotifications.filter { $0.name == .payloadSending }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.jsonObject.nonce }
    }

    var sentNonces: [String] {
        postedNotifications.filter { $0.name == .payloadSent }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.jsonObject.nonce }
    }

    var failedNonces: [String] {
        postedNotifications.filter { $0.name == .payloadFailed }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.jsonObject.nonce }
    }

    var failedErrors: [Error] {
        postedNotifications.filter { $0.name == .payloadFailed }
            .compactMap { $0.userInfo?[PayloadSender.errorKey] as? Error }
    }
}
