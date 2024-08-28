//
//  PayloadSenderTests.swift
//  PayloadSenderTests
//
//  Created by Frank Schmitt on 9/2/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import GenericJSON
import XCTest

@testable import ApptentiveKit

class PayloadSenderTests: XCTestCase, PayloadAuthenticationDelegate {
    var requestRetrier = SpyRequestStarter()
    var saver = SpySaver(containerURL: URL(string: "file:///tmp")!, filename: "PayloadQueue", fileManager: FileManager.default)
    var payloadSender: PayloadSender!
    var notificationCenter = MockNotificationCenter()
    var uncredentialedPayloadContext: Payload.Context!
    let anonymousCredentials = AnonymousAPICredentials(appCredentials: .init(key: "abc", signature: "123"), conversationCredentials: .init(id: "def", token: "456"))
    let jsonEncoder = JSONEncoder.apptentive
    var authFailureErrorResponse: ErrorResponse?

    var appCredentials: Apptentive.AppCredentials? {
        return self.anonymousCredentials.appCredentials
    }

    func authenticationDidFail(with errorResponse: ErrorResponse?) {
        self.authFailureErrorResponse = errorResponse
    }

    override func setUpWithError() throws {
        self.payloadSender = PayloadSender(requestRetrier: self.requestRetrier, notificationCenter: self.notificationCenter)
        payloadSender.authenticationDelegate = self

        self.uncredentialedPayloadContext = Payload.Context(tag: ".", credentials: .placeholder, sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: nil)
    }

    func testSessionID() throws {
        let payloadWithSession = try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext)

        self.uncredentialedPayloadContext.sessionID = nil

        let payloadWithoutSession = try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext)

        self.uncredentialedPayloadContext.sessionID = "sessionID2"

        let payloadWithOtherSession = try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext)

        let payloadWithSessionJSON = try JSON(JSONSerialization.jsonObject(with: payloadWithSession.bodyData!))
        let payloadWithoutSessionJSON = try JSON(JSONSerialization.jsonObject(with: payloadWithoutSession.bodyData!))
        let payloadWithOtherSessionJSON = try JSON(JSONSerialization.jsonObject(with: payloadWithOtherSession.bodyData!))

        XCTAssertNotNil(payloadWithSessionJSON["event"]!["session_id"])
        XCTAssertNil(payloadWithoutSessionJSON["event"]!["session_id"])
        XCTAssertNotEqual(payloadWithSessionJSON["event"]!["session_id"], payloadWithOtherSessionJSON["session_id"])
    }

    func testNormalOperation() throws {
        self.payloadSender.saver = self.saver

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])
        self.payloadSender.send(payloads[2])

        let nonces = payloads.map { $0.identifier }

        XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces)

        // Payload sender should not save queue to saver by default.
        XCTAssertEqual(self.saver.payloads.count, 0)

        try self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        XCTAssertEqual(self.saver.payloads.count, 3)

        // Mock the payload send request to succeed.
        self.requestRetrier.result = .success(PayloadResponse())

        // Start the payload sending process by setting the credentials.
        try payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        // Send one straggler payload while the requests are running.
        let credentialedPayloadContext = Payload.Context(
            tag: ".", credentials: .header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), encoder: self.jsonEncoder, encryptionContext: nil)
        let straggler = try Payload(wrapping: "test4", with: credentialedPayloadContext)

        self.payloadSender.send(straggler)

        let expectation = XCTestExpectation(description: "PayloadSender sends payloads")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            XCTAssertEqual(self.notificationCenter.sendingNonces, nonces + [straggler.identifier])

            do {
                try self.payloadSender.savePayloadsIfNeeded()

                // Payload queue should be empty
                XCTAssertEqual(self.saver.payloads.count, 0)

                // Retrier should have made a request.
                XCTAssertEqual(self.requestRetrier.requests.count, 4)

                XCTAssertEqual(self.notificationCenter.sentNonces, nonces + [straggler.identifier])
                XCTAssertEqual(self.notificationCenter.failedNonces, [])
            } catch let error {
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testHTTPUnauthorizedError() throws {
        self.payloadSender.saver = self.saver

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])

        let nonces = payloads.map { $0.identifier }

        XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces)

        // Payload sender should not save queue to saver by default.
        XCTAssertEqual(self.saver.payloads.count, 0)

        try self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        XCTAssertEqual(self.saver.payloads.count, 2)

        let errorResponse = ErrorResponse(error: "Mismatched sub claim", errorType: .mismatchedSubClaim)
        let errorData = try self.jsonEncoder.encode(errorResponse)

        // Mock the payload send request to fail.
        self.requestRetrier.result = .failure(HTTPClientError.unauthorized(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations/1234/events")!, statusCode: 401, httpVersion: nil, headerFields: nil)!, errorData))

        // Start the payload sending process by setting the credentials.
        try payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        XCTAssertNil(self.authFailureErrorResponse)

        let expectation = XCTestExpectation(description: "PayloadSender sends payloads")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            XCTAssertEqual(self.notificationCenter.sendingNonces, [nonces.first!])
            XCTAssertNotNil(self.authFailureErrorResponse)

            do {
                try self.payloadSender.savePayloadsIfNeeded()

                // Payload queue should still be full (of payloads with no credentials)
                XCTAssertEqual(self.saver.payloads.count, 2)

                XCTAssertEqual(self.notificationCenter.failedErrors.count, 0)

                // Retrier should have made a request.
                XCTAssertEqual(self.requestRetrier.requests.count, 1)
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
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])
        self.payloadSender.send(payloads[2])

        let nonces = payloads.map { $0.identifier }

        XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces)

        // Payload sender should not save queue to saver by default.
        XCTAssertEqual(self.saver.payloads.count, 0)

        try self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        XCTAssertEqual(self.saver.payloads.count, 3)

        // Mock the payload send request to fail.
        self.requestRetrier.result = .failure(HTTPClientError.clientError(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations/1234/events")!, statusCode: 422, httpVersion: nil, headerFields: nil)!, nil))

        // Start the payload sending process by setting the credentials.
        try payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        // Send one straggler payload while the requests are running.
        let credentialedPayloadContext = Payload.Context(
            tag: ".", credentials: .header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), encoder: self.jsonEncoder, encryptionContext: nil)
        let straggler = try Payload(wrapping: "test4", with: credentialedPayloadContext)

        self.payloadSender.send(straggler)

        let expectation = XCTestExpectation(description: "PayloadSender sends payloads")

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(500)) {
            XCTAssertEqual(self.notificationCenter.sendingNonces, nonces + [straggler.identifier])

            do {
                try self.payloadSender.savePayloadsIfNeeded()

                // Payload queue should be empty
                XCTAssertEqual(self.saver.payloads.count, 0)

                XCTAssertEqual(self.notificationCenter.failedNonces, nonces + [straggler.identifier])
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

    func testNoDiskAccess() throws {
        try self.payloadSender.send(Payload(wrapping: "test1", with: self.uncredentialedPayloadContext))

        // Mock the payload send request to succeed.
        self.requestRetrier.result = .success(PayloadResponse())

        // Start the payload sending process by setting the credentials.
        try payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        // Retrier should have made a request.
        XCTAssertEqual(self.requestRetrier.requests.count, 1)
    }

    func testImportantPayload() throws {
        self.payloadSender.saver = self.saver

        try self.payloadSender.send(Payload(wrapping: "test1", with: self.uncredentialedPayloadContext), persistEagerly: true)

        // Payload sender should save queue to saver when `persistEagerly` is set.
        XCTAssertEqual(self.saver.payloads.count, 1)
    }

    func testDrain() throws {
        self.payloadSender.saver = self.saver

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])
        self.payloadSender.send(payloads[2])

        let nonces = payloads.map { $0.identifier }

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
                let credentialedPayloadContext = Payload.Context(
                    tag: ".", credentials: .header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), encoder: self.jsonEncoder, encryptionContext: nil)
                let straggler = try! Payload(wrapping: "test4", with: credentialedPayloadContext)

                self.payloadSender.send(straggler)

                XCTAssertEqual(self.notificationCenter.enqueuedNonces, nonces + [straggler.identifier])
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
        try payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        self.wait(for: [expectation], timeout: 5)
    }

    func testAddCredentials() throws {
        let altPayloadContext = Payload.Context(tag: "alt", credentials: .placeholder, encoder: self.jsonEncoder, encryptionContext: nil)

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: altPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        self.payloadSender.send(payloads[0])
        self.payloadSender.send(payloads[1])
        self.payloadSender.send(payloads[2])

        XCTAssertEqual(self.payloadSender.payloads[0].credentials, .placeholder)
        XCTAssertEqual(self.payloadSender.payloads[1].credentials, .placeholder)
        XCTAssertEqual(self.payloadSender.payloads[2].credentials, .placeholder)

        self.requestRetrier.result = .success(PayloadResponse())

        try payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        XCTAssertNotEqual(self.payloadSender.payloads[0].credentials, .placeholder)
        XCTAssertEqual(self.payloadSender.payloads[1].credentials, .placeholder)
        XCTAssertNotEqual(self.payloadSender.payloads[2].credentials, .placeholder)

        try payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        XCTAssertNotNil(self.payloadSender.payloads[0].credentials)
        XCTAssertNotNil(self.payloadSender.payloads[1].credentials)
        XCTAssertNotNil(self.payloadSender.payloads[2].credentials)
    }

    class SpyRequestStarter: HTTPRequestStarting {
        var result: Result<PayloadResponse, Error>? = nil
        var requests = [HTTPRequestBuilding]()

        func start<T>(_ endpoint: HTTPRequestBuilding, identifier: String, completion: @escaping (Result<T, Error>) -> Void) where T: Decodable {
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
}

class MockNotificationCenter: NotificationCenter, @unchecked Sendable {
    var postedNotifications = [Notification]()

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        self.postedNotifications.append(Notification(name: aName, object: anObject, userInfo: aUserInfo))
    }
}

extension MockNotificationCenter {
    var enqueuedNonces: [String] {
        postedNotifications.filter { $0.name == .payloadEnqueued }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.identifier }
    }

    var sendingNonces: [String] {
        postedNotifications.filter { $0.name == .payloadSending }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.identifier }
    }

    var sentNonces: [String] {
        postedNotifications.filter { $0.name == .payloadSent }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.identifier }
    }

    var failedNonces: [String] {
        postedNotifications.filter { $0.name == .payloadFailed }
            .compactMap { ($0.userInfo?[PayloadSender.payloadKey] as? Payload)?.identifier }
    }

    var failedErrors: [Error] {
        postedNotifications.filter { $0.name == .payloadFailed }
            .compactMap { $0.userInfo?[PayloadSender.errorKey] as? Error }
    }
}
