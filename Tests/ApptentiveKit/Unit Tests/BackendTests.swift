//
//  BackendTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/4/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class BackendTests: XCTestCase {
    var backend: Backend!
    var requestor: SpyRequestor!
    var messageManager: MessageManager!
    var containerURL: URL!

    override func setUpWithError() throws {
        try MockEnvironment.cleanContainerURL()

        self.containerURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString)")

        self.requestor = SpyRequestor(responseData: Data())
        let environment = MockEnvironment()
        let queue = DispatchQueue(label: "Test Queue")
        self.messageManager = MessageManager(notificationCenter: NotificationCenter.default)

        var conversation = Conversation(environment: environment)
        conversation.appCredentials = Apptentive.AppCredentials(key: "123abc", signature: "456def")

        let client = HTTPClient(requestor: self.requestor, baseURL: URL(string: "https://api.apptentive.com/")!, userAgent: "foo")
        let requestRetrier = HTTPRequestRetrier(retryPolicy: HTTPRetryPolicy(), client: client, queue: queue)

        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)

        self.backend = Backend(
            queue: queue, conversation: conversation, targeter: Targeter(engagementManifest: EngagementManifest.placeholder), messageManager: self.messageManager, requestRetrier: requestRetrier,
            payloadSender: payloadSender)

        queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable(containerURL: self.containerURL, cachesURL: self.containerURL, environment: environment)

                self.requestor.responseData = try JSONEncoder().encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456"))

                self.backend.register(appCredentials: conversation.appCredentials!, completion: { _ in })
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: self.containerURL)
    }

    func testPersonChange() {
        let expectation = XCTestExpectation(description: "Person data sent")

        self.requestor.extraCompletion = {
            if self.requestor.request?.url == URL(string: "https://api.apptentive.com/conversations/def456/person") {
                expectation.fulfill()
            }
        }

        self.backend.queue.async {
            self.backend.conversation.person.name = "Testy McTestface"

            self.backend.syncConversationWithAPI()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testDeviceChange() {
        let expectation = XCTestExpectation(description: "Device data sent")

        self.requestor.extraCompletion = {
            if self.requestor.request?.url == URL(string: "https://api.apptentive.com/conversations/def456/device") {
                expectation.fulfill()
            }
        }

        self.backend.queue.async {
            self.backend.conversation.device.customData["string"] = "foo"

            self.backend.syncConversationWithAPI()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testAppReleaseChange() {
        let expectation = XCTestExpectation(description: "App release data sent")

        self.requestor.extraCompletion = {
            if self.requestor.request?.url == URL(string: "https://api.apptentive.com/conversations/def456/app_release") {
                expectation.fulfill()
            }
        }

        self.backend.queue.async {
            self.backend.conversation.appRelease.version = "1.2.3"

            self.backend.syncConversationWithAPI()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testOverridingStyles() {
        let credentials = Apptentive.AppCredentials(key: "", signature: "")
        let baseURL = URL(string: "https://api.apptentive.com/")!
        let queue = DispatchQueue(label: "Test Queue")
        let environment = MockEnvironment()
        let apptentive = Apptentive(baseURL: baseURL, containerDirectory: UUID().uuidString, backendQueue: queue, environment: environment)
        apptentive.theme = .none
        apptentive.register(with: credentials)
        XCTAssertTrue(apptentive.environment.isOverridingStyles)
    }
}
