//
//  PayloadSenderTests.swift
//  PayloadSenderTests
//
//  Created by Frank Schmitt on 9/2/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import GenericJSON
import Testing

@testable import ApptentiveKit

class PayloadSenderTests: PayloadAuthenticationDelegate, @unchecked Sendable {
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

    init() async throws {
        self.payloadSender = PayloadSender(requestRetrier: self.requestRetrier, notificationCenter: self.notificationCenter)
        await payloadSender.setAuthenticationDelegate(self)
        await payloadSender.setAppCredentials(Apptentive.AppCredentials(key: "abc", signature: "123"))

        self.uncredentialedPayloadContext = Payload.Context(tag: ".", credentials: .placeholder, sessionID: "abc123", encoder: self.jsonEncoder, encryptionContext: nil)
    }

    @Test func testSessionID() throws {
        let payloadWithSession = try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext)

        self.uncredentialedPayloadContext.sessionID = nil

        let payloadWithoutSession = try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext)

        self.uncredentialedPayloadContext.sessionID = "sessionID2"

        let payloadWithOtherSession = try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext)

        let payloadWithSessionJSON = try JSON(JSONSerialization.jsonObject(with: payloadWithSession.bodyData!))
        let payloadWithoutSessionJSON = try JSON(JSONSerialization.jsonObject(with: payloadWithoutSession.bodyData!))
        let payloadWithOtherSessionJSON = try JSON(JSONSerialization.jsonObject(with: payloadWithOtherSession.bodyData!))

        #expect(payloadWithSessionJSON["event"]!["session_id"] != nil)
        #expect(payloadWithoutSessionJSON["event"]!["session_id"] == nil)
        #expect(payloadWithSessionJSON["event"]!["session_id"] != payloadWithOtherSessionJSON["session_id"])
    }

    @Test func testNormalOperation() async throws {
        await self.payloadSender.setSaver(self.saver)

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        await self.payloadSender.send(payloads[0])
        await self.payloadSender.send(payloads[1])
        await self.payloadSender.send(payloads[2])

        let nonces = Set(payloads.map { $0.identifier })

        #expect(Set(self.notificationCenter.enqueuedNonces) == nonces)

        // Payload sender should not save queue to saver by default.
        #expect(self.saver.payloads.count == 0)

        try await self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        #expect(self.saver.payloads.count == 3)

        // Mock the payload send request to succeed.
        await self.requestRetrier.setResult(.success(PayloadResponse()))

        // Start the payload sending process by setting the credentials.
        try await payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        // Send one straggler payload while the requests are running.
        let credentialedPayloadContext = Payload.Context(
            tag: ".", credentials: .header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), encoder: self.jsonEncoder, encryptionContext: nil)
        let straggler = try Payload(wrapping: "test4", with: credentialedPayloadContext)

        await self.payloadSender.send(straggler)

        await self.notificationCenter.waitForNotification(with: Notification.Name.payloadSending, toHappen: 4)

        #expect(Set(self.notificationCenter.sendingNonces) == nonces.union([straggler.identifier]))

        await self.notificationCenter.waitForNotification(with: Notification.Name.payloadSent, toHappen: 4)

        try await self.payloadSender.savePayloadsIfNeeded()

        // Payload queue should be empty
        #expect(self.saver.payloads.count == 0)

        // Retrier should have made a request.
        let requestCount = await self.requestRetrier.requests.count
        #expect(requestCount == 4)

        #expect(Set(self.notificationCenter.sentNonces) == nonces.union([straggler.identifier]))
        #expect(self.notificationCenter.failedNonces == [])

    }

    @Test func testHTTPUnauthorizedError() async throws {
        await self.payloadSender.setSaver(self.saver)

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
        ]

        await self.payloadSender.send(payloads[0])
        await self.payloadSender.send(payloads[1])

        let nonces = payloads.map { $0.identifier }

        #expect(self.notificationCenter.enqueuedNonces == nonces)

        // Payload sender should not save queue to saver by default.
        #expect(self.saver.payloads.count == 0)

        try await self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        #expect(self.saver.payloads.count == 2)

        let errorResponse = ErrorResponse(error: "Mismatched sub claim", errorType: .mismatchedSubClaim)
        let errorData = try self.jsonEncoder.encode(errorResponse)

        // Mock the payload send request to fail.
        await self.requestRetrier.setResult(.failure(HTTPClientError.unauthorized(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations/1234/events")!, statusCode: 401, httpVersion: nil, headerFields: nil)!, errorData)))

        // Start the payload sending process by setting the credentials.
        try await payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        #expect(self.authFailureErrorResponse == nil)
        #expect(self.notificationCenter.sendingNonces == [nonces.last!])

        try await Task.sleep(nanoseconds: NSEC_PER_SEC)

        #expect(self.authFailureErrorResponse != nil)

        try await self.payloadSender.savePayloadsIfNeeded()

        // Payload queue should still be full (of payloads with no credentials)
        #expect(self.saver.payloads.count == 2)

        #expect(self.notificationCenter.failedErrors.count == 0)

        // Retrier should have made a request.
        let requestCount = await self.requestRetrier.requests.count
        #expect(requestCount == 1)
    }

    @Test func testHTTPClientError() async throws {
        await self.payloadSender.setSaver(self.saver)

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        await self.payloadSender.send(payloads[0])
        await self.payloadSender.send(payloads[1])
        await self.payloadSender.send(payloads[2])

        let nonces = Set(payloads.map { $0.identifier })

        #expect(Set(self.notificationCenter.enqueuedNonces) == nonces)

        // Payload sender should not save queue to saver by default.
        #expect(self.saver.payloads.count == 0)

        try await self.payloadSender.savePayloadsIfNeeded()

        // Payload sender should save queue to saver when asked.
        #expect(self.saver.payloads.count == 3)

        // Mock the payload send request to fail.
        await self.requestRetrier.setResult(.failure(HTTPClientError.clientError(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations/1234/events")!, statusCode: 422, httpVersion: nil, headerFields: nil)!, nil)))

        // Start the payload sending process by setting the credentials.
        try await payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        // Send one straggler payload while the requests are running.
        let credentialedPayloadContext = Payload.Context(
            tag: ".", credentials: .header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), encoder: self.jsonEncoder, encryptionContext: nil)
        let straggler = try Payload(wrapping: "test4", with: credentialedPayloadContext)

        await self.payloadSender.send(straggler)

        await self.notificationCenter.waitForNotification(with: Notification.Name.payloadSending, toHappen: 4)

        #expect(Set(self.notificationCenter.sendingNonces) == nonces.union([straggler.identifier]))

        await self.notificationCenter.waitForNotification(with: Notification.Name.payloadFailed, toHappen: 4)

        try await self.payloadSender.savePayloadsIfNeeded()

        // Payload queue should be empty
        #expect(self.saver.payloads.count == 0)

        #expect(Set(self.notificationCenter.failedNonces) == nonces.union([straggler.identifier]))
        #expect(self.notificationCenter.failedErrors.count == 4)

        // Retrier should have made a request.
        let requestCount = await self.requestRetrier.requests.count
        #expect(requestCount == 4)
    }

    @Test func testNoDiskAccess() async throws {
        try await self.payloadSender.send(Payload(wrapping: "test1", with: self.uncredentialedPayloadContext))

        // Mock the payload send request to succeed.
        await self.requestRetrier.setResult(.success(PayloadResponse()))

        // Start the payload sending process by setting the credentials.
        try await payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        try await Task.sleep(nanoseconds: 1_000_000)

        // Retrier should have made a request.
        let requestCount = await self.requestRetrier.requests.count
        #expect(requestCount == 1)
    }

    @Test func testImportantPayload() async throws {
        await self.payloadSender.setSaver(self.saver)

        try await self.payloadSender.send(Payload(wrapping: "test1", with: self.uncredentialedPayloadContext), persistEagerly: true)

        // Payload sender should save queue to saver when `persistEagerly` is set.
        #expect(self.saver.payloads.count == 1)
    }

    @Test func testDrain() async throws {
        await self.payloadSender.setSaver(self.saver)

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        await self.payloadSender.send(payloads[0])
        await self.payloadSender.send(payloads[1])
        await self.payloadSender.send(payloads[2])

        let nonces = Set(payloads.map { $0.identifier })

        #expect(Set(self.notificationCenter.enqueuedNonces) == nonces)

        // Payload sender should not save queue to saver by default.
        #expect(self.saver.payloads.count == 0)

        // Mock the payload send request to succeed.
        await self.requestRetrier.setResult(.success(PayloadResponse()))

        try await payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        await self.payloadSender.drain()

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)

        #expect(Set(self.notificationCenter.sendingNonces) == nonces)
        #expect(Set(self.notificationCenter.sentNonces) == nonces)
        #expect(self.notificationCenter.failedNonces == [])

        var requestCount = await self.requestRetrier.requests.count
        #expect(requestCount == 3)

        // Try sending another payload, making sure we'll be suspended.
        let credentialedPayloadContext = Payload.Context(
            tag: ".", credentials: .header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), encoder: self.jsonEncoder, encryptionContext: nil)
        let straggler = try! Payload(wrapping: "test4", with: credentialedPayloadContext)

        await self.payloadSender.send(straggler)

        #expect(Set(self.notificationCenter.enqueuedNonces) == nonces.union([straggler.identifier]))
        #expect(Set(self.notificationCenter.sentNonces) == nonces)
        #expect(self.notificationCenter.failedNonces == [])
        #expect(Set(self.notificationCenter.sendingNonces) == nonces)

        // Payload sender should be suspended and not send the last request.
        requestCount = await self.requestRetrier.requests.count
        #expect(requestCount == 3)

        await self.payloadSender.resume()

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)

        requestCount = await self.requestRetrier.requests.count
        #expect(requestCount == 4)
    }

    @Test func testAddCredentials() async throws {
        let altPayloadContext = Payload.Context(tag: "alt", credentials: .placeholder, encoder: self.jsonEncoder, encryptionContext: nil)

        let payloads = [
            try Payload(wrapping: "test1", with: self.uncredentialedPayloadContext),
            try Payload(wrapping: "test2", with: altPayloadContext),
            try Payload(wrapping: "test3", with: self.uncredentialedPayloadContext),
        ]

        await self.payloadSender.send(payloads[0])
        await self.payloadSender.send(payloads[1])
        await self.payloadSender.send(payloads[2])

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        var payloadCredentials = await self.payloadSender.credentials

        guard payloadCredentials.count == 3 else {
            throw TestError(reason: "Expected 3 payload credentials, but got \(payloadCredentials.count)")
        }

        #expect(payloadCredentials[0] == .placeholder)
        #expect(payloadCredentials[1] == .placeholder)
        #expect(payloadCredentials[2] == .placeholder)

        await self.requestRetrier.setResult(.success(PayloadResponse()))

        try await payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        payloadCredentials = await self.payloadSender.credentials
        #expect(payloadCredentials[0] != .placeholder)
        #expect(payloadCredentials[1] == .placeholder)
        #expect(payloadCredentials[2] != .placeholder)

        try await payloadSender.updateCredentials(.header(id: self.anonymousCredentials.conversationCredentials.id, token: self.anonymousCredentials.conversationCredentials.token), for: ".", encryptionContext: nil)

        payloadCredentials = await self.payloadSender.credentials
    }

    actor SpyRequestStarter: HTTPRequestStarting {
        var result: Result<PayloadResponse, Error>? = nil
        var requests = [HTTPRequestBuilding]()

        func start<T>(_ builder: HTTPRequestBuilding, identifier: String) async throws -> T where T: Decodable {
            guard let result = self.result as? Result<T, Error> else {
                throw TestError(reason: "Mock object type/nullability mismatch")
            }

            self.requests.append(builder)

            try await Task.sleep(nanoseconds: 10_000_000)

            switch result {
            case .success(let object):
                return object

            case .failure(let error):
                throw error
            }
        }

        func setResult(_ result: Result<PayloadResponse, Error>) {
            self.result = result
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
    var postedNotificationsCount = [Notification.Name: Int]()
    var continuation: CheckedContinuation<Void, Never>?
    var expectedName: Notification.Name?
    var expectedTimes: Int?

    func waitForNotification(with name: Notification.Name, toHappen times: Int) async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.expectedName = name
            self.expectedTimes = times
        }
    }

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        self.postedNotifications.append(Notification(name: aName, object: anObject, userInfo: aUserInfo))
        self.postedNotificationsCount[aName, default: 0] += 1

        if let expectedName, let expectedTimes, aName == expectedName, postedNotificationsCount[expectedName] ?? 0 >= expectedTimes {
            self.continuation?.resume()
            self.continuation = nil
            self.expectedName = nil
            self.expectedTimes = nil
        }
    }
}

extension PayloadSender {
    var credentials: [PayloadStoredCredentials] {
        return self.payloads.map { $0.credentials }
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
