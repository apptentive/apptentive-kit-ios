//
//  CustomerAuthenticationTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 3/20/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

actor SpyPayloadSender: PayloadSending {
    func drain() async {}

    func setAuthenticationDelegate(_ authenticationDelegate: any ApptentiveKit.PayloadAuthenticationDelegate) async {}

    func makeSaver(containerURL: URL, filename: String) {}

    func destroySaver() {}

    func setAppCredentials(_ appCredentials: ApptentiveKit.Apptentive.AppCredentials?) async {}

    var queuedPayloads = [Payload]()

    func load(from loader: ApptentiveKit.Loader) throws {}

    func send(_ payload: ApptentiveKit.Payload, persistEagerly: Bool) {
        self.queuedPayloads.append(payload)
    }

    func resume() {}

    func updateCredentials(_ credentials: PayloadStoredCredentials, for tag: String, encryptionContext: Payload.Context.EncryptionContext?) throws {}

    func savePayloadsIfNeeded() throws {}
}

actor CustomerAuthenticationTests {
    let dataProvider = MockDataProvider()
    var backend: Backend!
    let requestor: SpyRequestor
    let containerName: String = UUID().uuidString
    let backendDelegate: MockBackendDelegate!
    let jsonEncoder = JSONEncoder.apptentive
    let payloadSender = SpyPayloadSender()
    let fileManager = FileManager.default

    class MockBackendDelegate: BackendDelegate & MessageManagerApptentiveDelegate {
        func prefetchResources(at: [URL]) {}

        func setUnreadMessageCount(_ unreadMessageCount: Int) {
            self.unreadMessageCount = unreadMessageCount
        }

        func setPrefetchContainerURL(_ prefetchContainerURL: URL?) {}

        var unreadMessageCount: Int = 0

        let environment: ApptentiveKit.GlobalEnvironment = MockEnvironment()
        let interactionPresenter = InteractionPresenter()
        var resourceManager: ApptentiveKit.ResourceManager = ResourceManager(fileManager: MockFileManager(), requestor: SpyRequestor(responseData: Data()))

        func authenticationDidFail(with error: Error) {}
        func updateProperties(with: Conversation) {}
        func clearProperties() {}
    }

    init() async throws {
        self.backendDelegate = await MockBackendDelegate()

        try await MockEnvironment.cleanContainerURL()

        self.requestor = SpyRequestor(responseData: Data())
    }

    func createBackend(with roster: ConversationRoster) async {
        let messageManager = MessageManager(notificationCenter: NotificationCenter.default)
        let conversation = Conversation(dataProvider: self.dataProvider)
        let requestRetrier = HTTPRequestRetrier()
        let client = HTTPClient(requestor: self.requestor, baseURL: URL(string: "https://api.apptentive.com/")!, userAgent: "foo", languageCode: "de")
        let backendState = BackendState(isInForeground: true, isProtectedDataAvailable: false, roster: roster, fatalError: false)
        await requestRetrier.setClient(client)

        self.backend = Backend(
            conversation: conversation, state: backendState, containerName: containerName, targeter: Targeter(engagementManifest: EngagementManifest.placeholder), requestor: self.requestor, messageManager: messageManager,
            requestRetrier: requestRetrier,
            payloadSender: self.payloadSender, dataProvider: self.dataProvider, fileManager: FileManager())

        await self.backend.setDelegate(self.backendDelegate)
    }

    @Test func testCreateAnonymous() async throws {
        await self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        await self.backend.protectedDataDidBecomeAvailable()

        await self.requestor.setResponseData(try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
    }

    @Test func testLoginFromAnonymous() async throws {
        await self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        let containerURL = try await self.backend.containerURL

        await self.backend.protectedDataDidBecomeAvailable()

        await self.requestor.setResponseData(try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        guard case .anonymous(credentials: let anonymousCredentials) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        try! await self.backend.sendMessage(.init(nonce: UUID().uuidString, body: "Hello"))

        await self.requestor.setResponseData(try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey)))
        let loginCount = await self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0
        let launchCount = await self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount

        #expect(loginCount == 0)
        #expect(launchCount == 1)

        let _ = try await self.backend.logIn(with: barbaraJWT)
        guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        #expect(encryptionKey == fakeEncryptionKey)
        #expect(subject == "Barbara")
        #expect(loggedInCredentials.token == barbaraJWT)
        #expect(loggedInCredentials.id == anonymousCredentials.id)

        let conversationContainerURL = containerURL.appendingPathComponent(await self.backend.state.roster.active!.path)
        let plaintextConversationPath = conversationContainerURL.appendingPathComponent("Conversation.B.plist").path
        let plaintextMessageListPath = conversationContainerURL.appendingPathComponent("MessageList.B.plist").path
        let encryptedConversationPath = plaintextConversationPath + ".encrypted"
        let encryptedMessageListPath = plaintextMessageListPath + ".encrypted"

        // Give actor-based Message Manager time to do its thing
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        #expect(!self.fileManager.fileExists(atPath: plaintextConversationPath), "Unexpected plaintext Conversation file at \(plaintextConversationPath)")
        #expect(!self.fileManager.fileExists(atPath: plaintextMessageListPath), "Unexpected plaintext Message List file at \(plaintextMessageListPath)")

        #expect(self.fileManager.fileExists(atPath: encryptedConversationPath), "Missing encrypted Conversation file at \(encryptedConversationPath)")
        #expect(self.fileManager.fileExists(atPath: encryptedMessageListPath), "Missing encrypted Message List file at \(encryptedMessageListPath)")

        let loginCount2 = await self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0
        let launchCount2 = await self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount

        #expect(loginCount2 == 1)
        #expect(launchCount2 == 1)
    }

    @Test func testLoginFromLoggedOut() async throws {
        let path = UUID().uuidString

        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!

        // Write a roster to load that has no active conversation and one logged-out one.
        let roster = ConversationRoster(active: nil, loggedOut: [.init(state: .loggedOut(id: "def456", subject: "Barbara"), path: path)])

        // Write a logged-out conversation record
        var conversation = Conversation(dataProvider: self.dataProvider)
        conversation.person.emailAddress = "barb@example.com"
        let conversationData = try PropertyListEncoder().encode(conversation).encrypted(with: fakeEncryptionKey)

        await self.createBackend(with: .init(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let containerURL = try await self.backend.containerURL

        try self.fileManager.createDirectory(at: containerURL.appendingPathComponent(path), withIntermediateDirectories: true)
        try PropertyListEncoder().encode(roster).write(to: containerURL.appendingPathComponent("Roster.B.abc.plist"))
        try conversationData.write(to: containerURL.appendingPathComponent(path).appendingPathComponent("Conversation.B.plist.encrypted"))

        let jsonEncoder = JSONEncoder.apptentive
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        await self.requestor.setResponseData(try! jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/sessions")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        await self.backend.protectedDataDidBecomeAvailable()

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        let active = await self.backend.state.roster.active
        #expect(active == nil)

        await self.backend.setPersonEmailAddress("charlie@example.com")

        let loginCount = await self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0
        let launchCount = await self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount ?? 0

        #expect(loginCount == 0)
        #expect(launchCount == 0)

        try await self.backend.logIn(with: barbaraJWT)
        guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        #expect(encryptionKey == fakeEncryptionKey)
        #expect(subject == "Barbara")
        #expect(loggedInCredentials.token == barbaraJWT)
        #expect(loggedInCredentials.id == "def456")

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)

        let personEmailAddress = await self.backend.conversation?.person.emailAddress
        let loginCount2 = await self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0
        let launchCount2 = await self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount

        #expect(personEmailAddress == "barb@example.com")
        #expect(loginCount2 == 1)
        #expect(launchCount2 == 1)
    }

    @Test func testLoginFromNothing() async throws {
        let path = UUID().uuidString

        // Write a roster to load that has no active conversation and one logged-out one.
        let roster = ConversationRoster(active: nil, loggedOut: [.init(state: .loggedOut(id: "def457", subject: "Charlie"), path: path)])

        await self.createBackend(with: .init(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let jsonEncoder = JSONEncoder.apptentive
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        let containerURL = try await self.backend.containerURL
        try self.fileManager.createDirectory(at: containerURL.appendingPathComponent(path), withIntermediateDirectories: true)
        try PropertyListEncoder().encode(roster).write(to: containerURL.appendingPathComponent("Roster.B.abc.plist"))

        await self.backend.protectedDataDidBecomeAvailable()

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        let active = await self.backend.state.roster.active
        #expect(active == nil)

        await self.requestor.setResponseData(try! jsonEncoder.encode(ConversationResponse(token: barbaraJWT, id: "def456", deviceID: "def", personID: "456", encryptionKey: fakeEncryptionKey)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        let loginCount = await self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0
        let launchCount = await self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount ?? 0

        #expect(loginCount == 0)
        #expect(launchCount == 0)

        try await self.backend.logIn(with: barbaraJWT)
        guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        #expect(encryptionKey == fakeEncryptionKey)
        #expect(subject == "Barbara")
        #expect(loggedInCredentials.token == barbaraJWT)
        #expect(loggedInCredentials.id == "def456")

        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)

        let loginCount2 = await self.backend.conversation?.codePoints["com.apptentive#app#login"]?.totalCount ?? 0
        let launchCount2 = await self.backend.conversation?.codePoints["com.apptentive#app#launch"]?.totalCount ?? 0

        #expect(loginCount2 == 1)
        #expect(launchCount2 == 1)
    }

    @Test func testLogOut() async throws {
        await self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        // Write something to the caches directory
        let cachesURL = try await self.backend.cacheURL
        guard let imageURL = Bundle(for: Self.self).url(forResource: "2255A0CC-905B-4911-9448-16D801D31316#IMG_0004", withExtension: "jpeg", subdirectory: "A Data") else {
            throw TestError(reason: nil)
        }

        try self.fileManager.createDirectory(at: cachesURL, withIntermediateDirectories: true)
        try self.fileManager.copyItem(at: imageURL, to: cachesURL.appendingPathComponent("Test Attachment.jpeg"))
        let cachedAttachments = try self.fileManager.contentsOfDirectory(atPath: cachesURL.path)
        #expect(cachedAttachments.count == 1)

        await self.backend.protectedDataDidBecomeAvailable()

        await self.requestor.setResponseData(try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        guard case .anonymous(credentials: let anonymousCredentials) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        await self.requestor.setResponseData(try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/sessions")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        try await self.backend.logIn(with: barbaraJWT)
        guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        #expect(encryptionKey == fakeEncryptionKey)
        #expect(subject == "Barbara")
        #expect(loggedInCredentials.token == barbaraJWT)
        #expect(loggedInCredentials.id == anonymousCredentials.id)

        let logoutCount = await self.backend.conversation?.codePoints["com.apptentive#app#logout"]?.totalCount ?? 0
        #expect(logoutCount == 0)

        try await self.backend.logOut()

        let active = await self.backend.state.roster.active
        #expect(active == nil)

        let loggedOutRecord = try await #require(self.backend.state.roster.loggedOut.first)

        guard case .loggedOut(id: let id, subject: let subject) = loggedOutRecord.state else {
            throw TestError(reason: "Expected record to be in logged-out state.")
        }

        #expect(id == anonymousCredentials.id)
        #expect(subject == "Barbara")

        let _ = try await #require(self.payloadSender.queuedPayloads.first(where: { $0.method == HTTPMethod.delete }))

        // Give actor-based Message Manager time to do its thing
        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)

        let cachedAttachments2 = try self.fileManager.contentsOfDirectory(atPath: cachesURL.path)
        #expect(cachedAttachments2.count == 0, "\(cachedAttachments2.count) files found in \(cachesURL.path), expected 0")

        // Have to dig through payload queue to look for logout event since conversation no longer active at this point.
        var foundLogoutPayload = false
        for payload in await self.payloadSender.queuedPayloads.filter({ $0.path.hasSuffix("events") }) {
            guard payload.contentType == "application/octet-stream" else {
                continue  // not encrypted
            }

            let decryptedBody = try payload.bodyData!.decrypted(with: fakeEncryptionKey)
            if String(data: decryptedBody, encoding: .utf8)?.contains("com.apptentive#app#logout") ?? false {
                foundLogoutPayload = true
            }
        }

        #expect(foundLogoutPayload)
    }

    @Test func testUpdateToken() async throws {
        await self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"
        let newJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk4Njg0MDYuNTM2MTIsImlzcyI6IkNsaWVudFRlYW0iLCJzdWIiOiJCYXJiYXJhIiwiaWF0IjoxNjc5MzUwMDA4LjY4NTQzfQ.EypDkEHiXi9FOkThfoEw1EaaMVxw8n-mmdx0NXWp-TlulbzhjYcZk8oSR9p5L4BqYT_OSTsf29W1qxmA7lpaEA"

        await self.backend.protectedDataDidBecomeAvailable()

        await self.requestor.setResponseData(try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        guard case .anonymous(credentials: let anonymousCredentials) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        await self.requestor.setResponseData(try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey)))

        try await self.backend.logIn(with: barbaraJWT)
        guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        #expect(encryptionKey == fakeEncryptionKey)
        #expect(subject == "Barbara")
        #expect(loggedInCredentials.token == barbaraJWT)
        #expect(loggedInCredentials.id == anonymousCredentials.id)

        try await self.backend.updateToken(newJWT)
        guard case .loggedIn(let credentials, _, _) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "No longer logged in")
        }

        #expect(credentials.id == "def456")
        #expect(credentials.token == newJWT)
    }

    //    @Test func testLogoutBeforeLoginComplete() {
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

    @Test func testLoginBeforeRegister() async throws {
        await self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        await self.backend.protectedDataDidBecomeAvailable()

        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/sessions")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await self.requestor.setResponseData(try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil)))

        Task {
            let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        }

        await #expect(throws: ApptentiveError.self) {
            try await self.backend.logIn(with: barbaraJWT)
        }
    }

    @Test func testLoginWhileAnonymousPending() {
        // FIXME: Implement this.
    }

    @Test func testLoginWhileLoggedIn() async throws {
        await self.createBackend(with: ConversationRoster(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")!
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        await self.backend.protectedDataDidBecomeAvailable()

        await self.requestor.setResponseData(try self.jsonEncoder.encode(ConversationResponse(token: "abc", id: "def456", deviceID: "def", personID: "456", encryptionKey: nil)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        guard case .anonymous(credentials: let anonymousCredentials) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        await self.requestor.setResponseData(try! self.jsonEncoder.encode(SessionResponse(deviceID: "abc", personID: "123", encryptionKey: fakeEncryptionKey)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/sessions")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        try await self.backend.logIn(with: barbaraJWT)
        guard case .loggedIn(credentials: let loggedInCredentials, subject: let subject, encryptionKey: let encryptionKey) = await self.backend.state.roster.active?.state else {
            throw TestError(reason: "Failed to move state to logged in")
        }

        #expect(encryptionKey == fakeEncryptionKey)
        #expect(subject == "Barbara")
        #expect(loggedInCredentials.token == barbaraJWT)
        #expect(loggedInCredentials.id == anonymousCredentials.id)

        await #expect {
            try await self.backend.logIn(with: barbaraJWT)
        } throws: { error in
            guard case ApptentiveError.alreadyLoggedIn(subject: let subject, id: let id) = error as! ApptentiveError else {
                return false
            }

            return subject == "Barbara" && id == anonymousCredentials.id
        }
    }

    @Test func testLogoutWhileLoggedOut() async throws {
        let path = UUID().uuidString

        // Write a roster to load that has no active conversation and one logged-out one.
        let roster = ConversationRoster(active: nil, loggedOut: [.init(state: .loggedOut(id: "def457", subject: "Charlie"), path: path)])

        await self.createBackend(with: .init(active: .init(state: .placeholder, path: "."), loggedOut: []))

        let jsonEncoder = JSONEncoder.apptentive
        let fakeEncryptionKey = Data(base64Encoded: "CqlAobc4IyzVEU5ut/WPu0KoSI7ZowTiIlKncCXLZ9M=")
        let barbaraJWT =
            "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzUxMiJ9.eyJleHAiOjE2Nzk2MDkyMDYuNTM2MTE5OSwiaXNzIjoiQ2xpZW50VGVhbSIsInN1YiI6IkJhcmJhcmEiLCJpYXQiOjE2NzkzNTAwMDguNjg1NDN9.BZ0BKtaY55qMmSd24uTdDQxPtEPlHwKdUdmfTwG4hNlNMJXSOBAFHsIn0o6bmMAP1Wz_s4twRA8eK5mYnwluig"

        let containerURL = try await self.backend.containerURL
        try self.fileManager.createDirectory(at: containerURL.appendingPathComponent(path), withIntermediateDirectories: true)
        try PropertyListEncoder().encode(roster).write(to: containerURL.appendingPathComponent("Roster.B.abc.plist"))

        await self.backend.protectedDataDidBecomeAvailable()

        let _ = try await self.backend.register(appCredentials: Apptentive.AppCredentials(key: "abc", signature: "123"), region: .us)
        let active = await self.backend.state.roster.active
        #expect(active == nil)

        await self.requestor.setResponseData(try! jsonEncoder.encode(ConversationResponse(token: barbaraJWT, id: "def456", deviceID: "def", personID: "456", encryptionKey: fakeEncryptionKey)))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://api.apptentive.com/conversations")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        await #expect {
            try await self.backend.logOut()
        } throws: { error in
            guard case ApptentiveError.notLoggedIn = error as! ApptentiveError else {
                return false
            }

            return true
        }
    }
}
