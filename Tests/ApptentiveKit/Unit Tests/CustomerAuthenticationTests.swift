//
//  CustomerAuthenticationTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 3/20/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class SpyPayloadSender: PayloadSending {
    var queuedPayloads = [Payload]()

    func load(from loader: ApptentiveKit.Loader) throws {}

    func send(_ payload: ApptentiveKit.Payload, persistEagerly: Bool) {
        self.queuedPayloads.append(payload)
    }

    func drain(completionHandler: @escaping () -> Void) {}

    func resume() {}

    func updateCredentials(_ credentials: PayloadStoredCredentials, for tag: String, encryptionContext: Payload.Context.EncryptionContext?) throws {}

    func savePayloadsIfNeeded() throws {}

    var saver: ApptentiveKit.Saver<[ApptentiveKit.Payload]>?

    var authenticationDelegate: PayloadAuthenticationDelegate?
}

final class CustomerAuthenticationTests: XCTestCase {
    var dataProvider = MockDataProvider()
    var backend: Backend!
    var requestor: SpyRequestor!
    var containerName: String = UUID().uuidString
    let backendDelegate = MockBackendDelegate()
    let jsonEncoder = JSONEncoder.apptentive
    let payloadSender = SpyPayloadSender()
    let fileManager = FileManager.default

    class MockBackendDelegate: BackendDelegate {
        let environment: ApptentiveKit.GlobalEnvironment = MockEnvironment()
        let interactionPresenter = InteractionPresenter()
        var resourceManager: ApptentiveKit.ResourceManager = ResourceManager(fileManager: MockFileManager(), requestor: SpyRequestor(responseData: Data()))

        func authenticationDidFail(with error: Error) {}
        func updateProperties(with: Conversation) {}
        func clearProperties() {}
    }

    override func setUpWithError() throws {
        try MockEnvironment.cleanContainerURL()

        self.requestor = SpyRequestor(responseData: Data())
    }

    func createBackend(with roster: ConversationRoster) {
        let queue = DispatchQueue(label: "Test Queue")
        let messageManager = MessageManager(notificationCenter: NotificationCenter.default)
        let conversation = Conversation(dataProvider: self.dataProvider)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: HTTPRetryPolicy(), queue: queue)
        requestRetrier.client = HTTPClient(requestor: self.requestor, baseURL: URL(string: "https://api.apptentive.com/")!, userAgent: "foo", languageCode: "de")
        let backendState = BackendState(isInForeground: true, isProtectedDataAvailable: false, roster: roster, fatalError: false)

        self.backend = Backend(
            queue: queue, conversation: conversation, state: backendState, containerName: containerName, targeter: Targeter(engagementManifest: EngagementManifest.placeholder), requestor: self.requestor, messageManager: messageManager,
            requestRetrier: requestRetrier,
            payloadSender: self.payloadSender, dataProvider: self.dataProvider, fileManager: self.fileManager)

        self.backend.delegate = self.backendDelegate
    }

    override func tearDownWithError() throws {
        //self.containerURL.flatMap { try? FileManager.default.removeItem(at: $0) }
    }

    func testCreateAnonymous() {
        self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let expectation = self.expectation(description: "Backend configured")

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.requestor.responseData = try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us,
                    completion: { _ in
                        expectation.fulfill()
                    })
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testLoginFromAnonymous() throws {
        self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let anonymousExpectation = self.expectation(description: "Backend configured")
        let loginExpectation = self.expectation(description: "Backend logged in")
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"
        let containerURL = try self.backend.containerURL

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.requestor.responseData = try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us
                ) { _ in
                    guard case .anonymous(credentials: let anonymousCredentials) = self.backend.state.roster.active?.state else {
                        XCTFail("Failed to move state to logged in")
                        return
                    }

                    anonymousExpectation.fulfill()
                    try! self.backend.sendMessage(.init(nonce: UUID().uuidString, body: "Hello"))

                    self.requestor.responseData = try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey))
                    XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0, 0)
                    XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount, 1)

                    self.backend.logIn(with: barbaraJWT) { result in

                        switch result {
                        case .success:
                            guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = self.backend.state.roster.active?.state else {
                                XCTFail("Failed to move state to logged in")
                                return
                            }

                            XCTAssertEqual(encryptionKey, fakeEncryptionKey)
                            XCTAssertEqual(subject, "Barbara")
                            XCTAssertEqual(loggedInCredentials.token, barbaraJWT)
                            XCTAssertEqual(loggedInCredentials.id, anonymousCredentials.id)

                            let conversationContainerURL = containerURL.appendingPathComponent(self.backend.state.roster.active!.path)
                            let plaintextConversationPath = conversationContainerURL.appendingPathComponent("Conversation.B.plist").path
                            let plaintextMessageListPath = conversationContainerURL.appendingPathComponent("MessageList.B.plist").path
                            let encryptedConversationPath = plaintextConversationPath + ".encrypted"
                            let encryptedMessageListPath = plaintextMessageListPath + ".encrypted"

                            XCTAssertFalse(self.fileManager.fileExists(atPath: plaintextConversationPath), "Unexpected plaintext Conversation file at \(plaintextConversationPath)")
                            XCTAssertFalse(self.fileManager.fileExists(atPath: plaintextMessageListPath), "Unexpected plaintext Message List file at \(plaintextMessageListPath)")

                            XCTAssertTrue(self.fileManager.fileExists(atPath: encryptedConversationPath), "Missing encrypted Conversation file at \(encryptedConversationPath)")
                            XCTAssertTrue(self.fileManager.fileExists(atPath: encryptedMessageListPath), "Missing encrypted Message List file at \(encryptedMessageListPath)")

                            XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount, 1)
                            XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount, 1)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }

                        loginExpectation.fulfill()
                    }
                }
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [anonymousExpectation, loginExpectation], timeout: 5)
    }

    func testLoginFromLoggedOut() throws {
        let path = UUID().uuidString

        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!

        // Write a roster to load that has no active conversation and one logged-out one.
        let roster = ConversationRoster(active: nil, loggedOut: [.init(state: .loggedOut(id: "def456", subject: "Barbara"), path: path)])

        // Write a logged-out conversation record
        var conversation = Conversation(dataProvider: self.dataProvider)
        conversation.person.emailAddress = "barb@example.com"
        let conversationData = try PropertyListEncoder().encode(conversation).encrypted(with: fakeEncryptionKey)

        self.createBackend(with: .init(active: .init(state: .placeholder, path: "."), loggedOut: []))

        try self.fileManager.createDirectory(at: self.backend.containerURL.appendingPathComponent(path), withIntermediateDirectories: true)
        try PropertyListEncoder().encode(roster).write(to: self.backend.containerURL.appendingPathComponent("Roster.B.abc.plist"))
        try conversationData.write(to: self.backend.containerURL.appendingPathComponent(path).appendingPathComponent("Conversation.B.plist.encrypted"))

        let registerExpectation = self.expectation(description: "Backend configured")
        let loginExpectation = self.expectation(description: "Backend logged in")
        let jsonEncoder = JSONEncoder.apptentive
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us
                ) { _ in
                    XCTAssertNil(self.backend.state.roster.active)

                    registerExpectation.fulfill()

                    self.requestor.responseData = try! jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey))

                    self.backend.setPersonEmailAddress("charlie@example.com")
                    XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0, 0)
                    XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount ?? 0, 0)

                    self.backend.logIn(with: barbaraJWT) { result in

                        switch result {
                        case .success:
                            guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = self.backend.state.roster.active?.state else {
                                XCTFail("Failed to move state to logged in")
                                return
                            }

                            XCTAssertEqual(encryptionKey, fakeEncryptionKey)
                            XCTAssertEqual(subject, "Barbara")
                            XCTAssertEqual(loggedInCredentials.token, barbaraJWT)
                            XCTAssertEqual(loggedInCredentials.id, "def456")

                            XCTAssertEqual(self.backend.conversation?.person.emailAddress, "barb@example.com")
                            XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount, 1)
                            XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount, 1)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }

                        loginExpectation.fulfill()
                    }
                }
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [registerExpectation, loginExpectation], timeout: 5)
    }

    func testLoginFromNothing() throws {
        let path = UUID().uuidString

        // Write a roster to load that has no active conversation and one logged-out one.
        let roster = ConversationRoster(active: nil, loggedOut: [.init(state: .loggedOut(id: "def457", subject: "Charlie"), path: path)])

        self.createBackend(with: .init(active: .init(state: .placeholder, path: "."), loggedOut: []))

        try self.fileManager.createDirectory(at: self.backend.containerURL.appendingPathComponent(path), withIntermediateDirectories: true)
        try PropertyListEncoder().encode(roster).write(to: self.backend.containerURL.appendingPathComponent("Roster.B.abc.plist"))

        let registerExpectation = self.expectation(description: "Backend configured")
        let loginExpectation = self.expectation(description: "Backend logged in")
        let jsonEncoder = JSONEncoder.apptentive
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us
                ) { _ in
                    XCTAssertNil(self.backend.state.roster.active)

                    registerExpectation.fulfill()

                    self.requestor.responseData = try! jsonEncoder.encode(ConversationResponse(token: barbaraJWT, id: "def456", deviceID: "def", personID: "456", encryptionKey: fakeEncryptionKey))
                    XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0, 0)
                    XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount ?? 0, 0)

                    self.backend.logIn(with: barbaraJWT) { result in
                        switch result {
                        case .success:
                            guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = self.backend.state.roster.active?.state else {
                                XCTFail("Failed to move state to logged in")
                                return
                            }

                            XCTAssertEqual(encryptionKey, fakeEncryptionKey)
                            XCTAssertEqual(subject, "Barbara")
                            XCTAssertEqual(loggedInCredentials.token, barbaraJWT)
                            XCTAssertEqual(loggedInCredentials.id, "def456")
                            XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount, 1)
                            XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount, 1)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }

                        loginExpectation.fulfill()
                    }
                }
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [registerExpectation, loginExpectation], timeout: 5)
    }

    func testLogOut() throws {
        self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let anonymousExpectation = self.expectation(description: "Backend configured")
        let loginExpectation = self.expectation(description: "Backend logged in")
        let logoutExpectation = self.expectation(description: "Backend logged out")
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        // Write something to the caches directory
        let cachesURL = try self.backend.cacheURL
        guard let imageURL = Bundle(for: Self.self).url(forResource: "2255A0CC-905B-4911-9448-16D801D31316#IMG_0004", withExtension: "jpeg", subdirectory: "A Data") else {
            throw TestError()
        }
        try self.fileManager.createDirectory(at: cachesURL, withIntermediateDirectories: true)
        try self.fileManager.copyItem(at: imageURL, to: cachesURL.appendingPathComponent("Test Attachment.jpeg"))
        let cachedAttachments = try self.fileManager.contentsOfDirectory(atPath: cachesURL.path)
        XCTAssertEqual(cachedAttachments.count, 1)

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.requestor.responseData = try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us
                ) { _ in
                    guard case .anonymous(credentials: let anonymousCredentials) = self.backend.state.roster.active?.state else {
                        XCTFail("Failed to move state to logged in")
                        return
                    }

                    anonymousExpectation.fulfill()

                    self.requestor.responseData = try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey))

                    self.backend.logIn(with: barbaraJWT) { result in

                        switch result {
                        case .success:
                            guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = self.backend.state.roster.active?.state else {
                                XCTFail("Failed to move state to logged in")
                                return
                            }

                            XCTAssertEqual(encryptionKey, fakeEncryptionKey)
                            XCTAssertEqual(subject, "Barbara")
                            XCTAssertEqual(loggedInCredentials.token, barbaraJWT)
                            XCTAssertEqual(loggedInCredentials.id, anonymousCredentials.id)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }

                        XCTAssertEqual(self.backend.conversation?.codePoints["com.apptentive#app#logout"]?.totalCount ?? 0, 0)

                        do {
                            try self.backend.logOut()

                            XCTAssertNil(self.backend.state.roster.active)
                            guard let loggedOutRecord = self.backend.state.roster.loggedOut.first else {
                                XCTFail("Expected an item in roster's list of logged-out records.")
                                return
                            }

                            guard case .loggedOut(id: let id, subject: let subject) = loggedOutRecord.state else {
                                XCTFail("Expected record to be in logged-out state.")
                                return
                            }

                            XCTAssertEqual(id, anonymousCredentials.id)
                            XCTAssertEqual(subject, "Barbara")

                            guard let _ = self.payloadSender.queuedPayloads.first(where: { $0.method == HTTPMethod.delete }) else {
                                XCTFail("No logout payload in payload queue.")
                                return
                            }

                            let cachedAttachments = try self.fileManager.contentsOfDirectory(atPath: cachesURL.path)
                            XCTAssertEqual(cachedAttachments.count, 0, "\(cachedAttachments.count) files found in \(cachesURL.path), expected 0")

                            // Have to dig through payload queue to look for logout event since conversation no longer active at this point.
                            var foundLogoutPayload = false
                            for payload in self.payloadSender.queuedPayloads.filter({ $0.path.hasSuffix("events") }) {
                                guard payload.contentType == "application/octet-stream" else {
                                    continue  // not encrypted
                                }

                                let decryptedBody = try payload.bodyData!.decrypted(with: fakeEncryptionKey)
                                if String(data: decryptedBody, encoding: .utf8)?.contains("com.apptentive#app#logout") ?? false {
                                    foundLogoutPayload = true
                                }
                            }

                            XCTAssertTrue(foundLogoutPayload)

                            logoutExpectation.fulfill()
                        } catch let error {
                            XCTFail(error.localizedDescription)
                        }

                        loginExpectation.fulfill()
                    }
                }
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [anonymousExpectation, loginExpectation, logoutExpectation], timeout: 5)
    }

    func testUpdateToken() throws {
        self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let anonymousExpectation = self.expectation(description: "Backend configured")
        let loginExpectation = self.expectation(description: "Backend logged in")
        let updateTokenExpectation = self.expectation(description: "Backend updated token")
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"
        let newJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk4Njg0MDYuNTM2MTIsImlzcyI6IkNsaWVudFRlYW0iLCJzdWIiOiJCYXJiYXJhIiwiaWF0IjoxNjc5MzUwMDA4LjY4NTQzfQ.EypDkEHiXi9FOkThfoEw1EaaMVxw8n-mmdx0NXWp-TlulbzhjYcZk8oSR9p5L4BqYT_OSTsf29W1qxmA7lpaEA"

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.requestor.responseData = try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us
                ) { _ in
                    guard case .anonymous(credentials: let anonymousCredentials) = self.backend.state.roster.active?.state else {
                        XCTFail("Failed to move state to logged in")
                        return
                    }

                    anonymousExpectation.fulfill()

                    self.requestor.responseData = try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey))

                    self.backend.logIn(with: barbaraJWT) { result in

                        switch result {
                        case .success:
                            guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = self.backend.state.roster.active?.state else {
                                XCTFail("Failed to move state to logged in")
                                return
                            }

                            XCTAssertEqual(encryptionKey, fakeEncryptionKey)
                            XCTAssertEqual(subject, "Barbara")
                            XCTAssertEqual(loggedInCredentials.token, barbaraJWT)
                            XCTAssertEqual(loggedInCredentials.id, anonymousCredentials.id)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }

                        self.backend.updateToken(newJWT) { result in
                            switch result {
                            case .success:
                                guard case .loggedIn(let credentials, _, _) = self.backend.state.roster.active?.state else {
                                    XCTFail("No longer logged in")
                                    break
                                }

                                XCTAssertEqual(credentials.id, "def456")
                                XCTAssertEqual(credentials.token, newJWT)

                            case .failure(let error):
                                XCTFail(error.localizedDescription)
                            }

                            updateTokenExpectation.fulfill()
                        }

                        loginExpectation.fulfill()
                    }
                }
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [anonymousExpectation, loginExpectation, updateTokenExpectation], timeout: 5)
    }

    //    func testLogoutBeforeLoginComplete() {
    //        self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))
    //        self.requestor.delay = 0.5
    //
    //        let anonymousExpectation = self.expectation(description: "Backend configured")
    //        let logoutExpectation = self.expectation(description: "Backend failed to log in")
    //        let barbaraJWT =
    //            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"
    //
    //        self.backend.queue.async {
    //            do {
    //                try self.backend.protectedDataDidBecomeAvailable(environment: self.backendDelegate.environment)
    //
    //                self.requestor.responseData = try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))
    //
    //                self.backend.register(
    //                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), environment: self.backendDelegate.environment
    //                ) { _ in
    //                    guard case .anonymous(credentials: let anonymousCredentials) = self.backend.state.roster.active?.state else {
    //                        XCTFail("Failed to move state to logged in")
    //                        return
    //                    }
    //
    //                    anonymousExpectation.fulfill()
    //
    //                    self.backend.logIn(with: barbaraJWT) { result in
    //                        if case .success = result {
    //                            XCTFail("Login request should not succeed if logOut() called before it finishes.")
    //                        }
    //
    //                        logoutExpectation.fulfill()
    //                    }
    //
    //                    do {
    //                        try self.backend.logOut()
    //
    //                        XCTAssertNil(self.backend.state.roster.active)
    //                        guard let loggedOutRecord = self.backend.state.roster.loggedOut.first else {
    //                            XCTFail("Expected an item in roster's list of logged-out records.")
    //                            return
    //                        }
    //
    //                        guard case .loggedOut(id: let id, subject: let subject) = loggedOutRecord.state else {
    //                            XCTFail("Expected record to be in logged-out state.")
    //                            return
    //                        }
    //
    //                        XCTAssertEqual(id, anonymousCredentials.id)
    //                        XCTAssertEqual(subject, "Barbara")
    //                    } catch {
    //                        // OK to get "not logged in" error here.
    //                    }
    //                }
    //            } catch let error {
    //                XCTFail(error.localizedDescription)
    //            }
    //        }
    //
    //        self.wait(for: [anonymousExpectation, logoutExpectation], timeout: 5)
    //    }

    func testLoginBeforeRegister() {
        self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let anonymousExpectation = self.expectation(description: "Backend configured")
        let loginExpectation = self.expectation(description: "Backend logged in")
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.requestor.responseData = try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us
                ) { _ in
                    anonymousExpectation.fulfill()
                }

                self.requestor.responseData = try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey))

                self.backend.logIn(with: barbaraJWT) { result in
                    if case .success = result {
                        XCTFail("Login should fail if called before register() completes.")
                    }

                    loginExpectation.fulfill()
                }

            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [anonymousExpectation, loginExpectation], timeout: 5)
    }

    func testLoginWhileAnonymousPending() {
        // FIXME: Implement this.
    }

    func testLoginWhileLoggedIn() {
        self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let anonymousExpectation = self.expectation(description: "Backend configured")
        let loginExpectation = self.expectation(description: "Backend logged in")
        let loginExpectation2 = self.expectation(description: "Backend second login attempt")
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.requestor.responseData = try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil))

                self.backend.register(
                    appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us
                ) { _ in
                    guard case .anonymous(credentials: let anonymousCredentials) = self.backend.state.roster.active?.state else {
                        XCTFail("Failed to move state to logged in")
                        return
                    }

                    anonymousExpectation.fulfill()

                    self.requestor.responseData = try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey))

                    self.backend.logIn(with: barbaraJWT) { result in

                        switch result {
                        case .success:
                            guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = self.backend.state.roster.active?.state else {
                                XCTFail("Failed to move state to logged in")
                                return
                            }

                            XCTAssertEqual(encryptionKey, fakeEncryptionKey)
                            XCTAssertEqual(subject, "Barbara")
                            XCTAssertEqual(loggedInCredentials.token, barbaraJWT)
                            XCTAssertEqual(loggedInCredentials.id, anonymousCredentials.id)

                        case .failure(let error):
                            XCTFail(error.localizedDescription)
                        }

                        loginExpectation.fulfill()

                        self.backend.logIn(with: barbaraJWT) { result in
                            guard case .failure(let error) = result else {
                                XCTFail("Expected error when trying to log in while already logged in")
                                return
                            }

                            guard case ApptentiveError.alreadyLoggedIn(subject: let subject, id: let id) = error else {
                                XCTFail("Expected error when trying to log in while already logged in")
                                return
                            }

                            XCTAssertEqual(subject, "Barbara")
                            XCTAssertEqual(id, anonymousCredentials.id)

                            loginExpectation2.fulfill()
                        }
                    }
                }
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [anonymousExpectation, loginExpectation, loginExpectation2], timeout: 5)

    }

    func testLogoutWhileLoggedOut() throws {
        let path = UUID().uuidString

        // Write a roster to load that has no active conversation and one logged-out one.
        let roster = ConversationRoster(active: nil, loggedOut: [.init(state: .loggedOut(id: "def457", subject: "Charlie"), path: path)])

        self.createBackend(with: .init(active: .init(state: .placeholder, path: "."), loggedOut: []))

        try self.fileManager.createDirectory(at: self.backend.containerURL.appendingPathComponent(path), withIntermediateDirectories: true)
        try PropertyListEncoder().encode(roster).write(to: self.backend.containerURL.appendingPathComponent("Roster.B.abc.plist"))

        let registerExpectation = self.expectation(description: "Backend configured")
        let logoutFailureExpectation = self.expectation(description: "Backend failed to log out when not logged in")
        let jsonEncoder = JSONEncoder.apptentive
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        self.backend.queue.async {
            do {
                try self.backend.protectedDataDidBecomeAvailable()

                self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us) { _ in
                    XCTAssertNil(self.backend.state.roster.active)

                    registerExpectation.fulfill()

                    self.requestor.responseData = try! jsonEncoder.encode(ConversationResponse(token: barbaraJWT, id: "def456", deviceID: "def", personID: "456", encryptionKey: fakeEncryptionKey))

                    // The type-checker gets confused if this isn't wrapped in a func.
                    func logOutBackend() {
                        XCTAssertThrowsError(try self.backend.logOut(), "Expected log out to throw error when already logged out") { error in
                            guard case ApptentiveError.notLoggedIn = error else {
                                XCTFail("Expected not logged in error")
                                return
                            }
                        }
                    }

                    logOutBackend()

                    logoutFailureExpectation.fulfill()
                }
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }

        self.wait(for: [registerExpectation, logoutFailureExpectation], timeout: 5)
    }
}
