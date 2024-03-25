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
    var containerURL: URL?
    let backendDelegate = MockBackendDelegate()
    let jsonEncoder = JSONEncoder.apptentive

    class MockBackendDelegate: BackendDelegate {
        var resourceManager: ApptentiveKit.ResourceManager = ResourceManager(fileManager: MockFileManager(), requestor: SpyRequestor(responseData: Data()))
        let environment: ApptentiveKit.GlobalEnvironment = MockEnvironment()
        let interactionPresenter = InteractionPresenter()
        var authError: Error?

        func authenticationDidFail(with error: Swift.Error) {
            self.authError = error
        }
    }

    /// Creates a Backend object with a
    override func setUpWithError() throws {
        try MockEnvironment.cleanContainerURL()

        self.containerURL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString)")

        self.requestor = SpyRequestor(responseData: Data())
        let environment = MockEnvironment()
        let queue = DispatchQueue(label: "Test Queue")
        self.messageManager = MessageManager(notificationCenter: NotificationCenter.default)

        let conversation = Conversation(environment: environment)

        let client = HTTPClient(requestor: self.requestor, baseURL: URL(string: "https://api.apptentive.com/")!, userAgent: "foo", languageCode: "de")
        let requestRetrier = HTTPRequestRetrier(retryPolicy: HTTPRetryPolicy(), client: client, queue: queue)

        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let roster = ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: [])

        let backendState = BackendState(isInForeground: true, isProtectedDataAvailable: true, roster: roster, fatalError: false)

        self.backend = Backend(
            queue: queue, conversation: conversation, state: backendState, containerName: containerURL!.lastPathComponent, targeter: Targeter(engagementManifest: EngagementManifest.placeholder), messageManager: self.messageManager,
            requestRetrier: requestRetrier,
            payloadSender: payloadSender, isDebugBuild: true)

        self.backend.delegate = self.backendDelegate

        let expectation = self.expectation(description: "Backend configured")

        queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable(environment: environment)

                self.requestor.responseData = try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), environment: environment,
                    completion: { _ in
                        expectation.fulfill()
                    })
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [expectation], timeout: 5)
    }

    override func tearDownWithError() throws {
        self.containerURL.flatMap { try? FileManager.default.removeItem(at: $0) }
    }

    func testPersonChange() {
        let expectation = XCTestExpectation(description: "Person data sent")

        self.requestor.extraCompletion = {
            if self.requestor.request?.url == URL(string: "https://api.apptentive.com/conversations/def456/person") {
                expectation.fulfill()
            }
        }

        self.backend.queue.async {
            self.backend.conversation?.person.name = "Testy McTestface"

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
            self.backend.conversation?.device.customData["string"] = "foo"

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
            self.backend.conversation?.appRelease.version = "1.2.3"

            self.backend.syncConversationWithAPI()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    //    func testPayloadWithBadToken() throws {
    //        let expectation = XCTestExpectation(description: "Payload failed sent")
    //
    //        // Mock the payload send request to fail.
    //        let errorResponse = ErrorResponse(error: "Mismatched sub claim", errorType: .mismatchedSubClaim)
    //        let errorData = try self.jsonEncoder.encode(errorResponse)
    //
    //        self.requestor.responseData = errorData
    //        self.requestor.error = .unauthorized(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations/def456/messages")!, statusCode: 401, httpVersion: nil, headerFields: nil)!, errorData)
    //
    //        self.requestor.extraCompletion = {
    //            if self.requestor.request?.httpMethod == "POST" {
    //                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
    //                    XCTAssertNotNil(self.backendDelegate.authError)
    //                    expectation.fulfill()
    //                }
    //            }
    //        }
    //
    //        self.backend.queue.async {
    //            XCTAssertNil(self.backendDelegate.authError)
    //
    //            try? self.backend.sendMessage(.init(nonce: UUID().uuidString, body: "Test"))
    //        }
    //
    //        self.wait(for: [expectation], timeout: 5)
    //    }

    //    func testOverridingStyles() {
    //        apptentiveAssertionHandler = { message, file, line in
    //            print("\(file):\(line): Apptentive critical error: \(message())")
    //        }
    //        let credentials = Apptentive.AppCredentials(key: "", signature: "")
    //        let baseURL = URL(string: "https://api.apptentive.com/")!
    //        let queue = DispatchQueue(label: "Test Queue")
    //        let environment = MockEnvironment()
    //        let apptentive = Apptentive(baseURL: baseURL, containerDirectory: UUID().uuidString, backendQueue: queue, environment: environment)
    //        apptentive.theme = .none
    //        apptentive.register(with: credentials)
    //        XCTAssertTrue(apptentive.environment.isOverridingStyles)
    //    }
}
