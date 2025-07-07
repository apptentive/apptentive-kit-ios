//
//  ApptentiveTests.swift
//  ApptentiveFeatureTests
//
//  Created by Frank Schmitt on 3/27/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

@MainActor
struct ApptentiveTests {
    let apptentive: Apptentive
    let backend = SpyBackend()
    let environment = MockEnvironment()
    let dataProvider = MockDataProvider()

    init() {
        let requestor = SpyRequestor(responseData: Data())
        Apptentive.alreadyInitialized = false
        self.apptentive = Apptentive(backend: backend, requestor: requestor, dataProvider: dataProvider, environment: environment)
    }

    @Test func testRegister() async throws {
        self.apptentive.theme = .none

        try await self.apptentive.register(with: .init(key: "IOS-abc", signature: "123"))
    }

    @Test func testRegisterWithInvalidCredentials() async throws {
        self.apptentive.theme = .none

        await #expect(throws: ApptentiveError.invalidAppCredentials) {
            try await self.apptentive.register(with: .init(key: "IOS-def", signature: "456"))
        }
    }

    @Test func testRegisterWithAndroidCredentials() async throws {
        self.apptentive.theme = .none

        await #expect(throws: ApptentiveError.invalidAppCredentials) {
            try await self.apptentive.register(with: .init(key: "ANDROID-def", signature: "123"))
        }
    }

    @Test func testRegisterWithCompletion() async throws {
        self.apptentive.theme = .none

        try await withCheckedThrowingContinuation { continuation in
            self.apptentive.register(with: .init(key: "IOS-abc", signature: "123")) { result in
                continuation.resume(with: result)
            }
        }
    }

    @Test func testRegisterWithInvalidCredentialsWithCompletion() async throws {
        self.apptentive.theme = .none

        await #expect(throws: ApptentiveError.invalidAppCredentials) {
            try await withCheckedThrowingContinuation { continuation in
                self.apptentive.register(with: .init(key: "IOS-def", signature: "456")) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test func testEngage() async throws {
        let viewController = UIViewController()
        let result = try await self.apptentive.engage(event: "Test", from: viewController)

        #expect(result)
        #expect(self.apptentive.interactionPresenter.presentingViewController == viewController)
        await #expect(self.backend.engagedEvent?.name == "Test")
    }

    @Test func testEngageWithCompletion() async throws {
        let viewController = UIViewController()
        let result = try await withCheckedThrowingContinuation { continuation in
            self.apptentive.engage(event: "Test", from: viewController) { result in
                continuation.resume(with: result)
            }
        }

        #expect(result)
        #expect(self.apptentive.interactionPresenter.presentingViewController == viewController)
        await #expect(self.backend.engagedEvent?.name == "Test")
    }

    @Test func testPresentMessageCenter() async throws {
        let viewController = UIViewController()
        var customData = CustomData()
        customData["String"] = "Test"
        customData["Boolean"] = true
        customData["Number"] = 3

        let result = try await self.apptentive.presentMessageCenter(from: viewController, with: customData)

        #expect(result)
        #expect(self.apptentive.interactionPresenter.presentingViewController == viewController)
        await #expect(self.backend.engagedEvent?.codePointName == Event.showMessageCenter.codePointName)
        await #expect(self.backend.messageCenterCustomData == customData)
    }

    @Test func testPresentMessageCenterWithCompletion() async throws {
        let viewController = UIViewController()
        var customData = CustomData()
        customData["String"] = "Test"
        customData["Boolean"] = true
        customData["Number"] = 3

        let result = try await withCheckedThrowingContinuation { continuation in
            self.apptentive.presentMessageCenter(from: viewController, with: customData) { result in
                continuation.resume(with: result)
            }
        }

        #expect(result)
        #expect(self.apptentive.interactionPresenter.presentingViewController == viewController)
        await #expect(self.backend.engagedEvent?.codePointName == Event.showMessageCenter.codePointName)
        await #expect(self.backend.messageCenterCustomData == customData)
    }

    @Test func testSendTextAttachment() async throws {
        self.apptentive.sendAttachment("Hello")

        await #expect(self.backend.messageCenterCustomData == nil)
        await #expect(self.backend.sentMessages[0].body == "Hello")
    }

    @Test func testSendImageAttachment() async throws {
        let imageURL = Bundle(for: BundleFinder.self).url(forResource: "dog", withExtension: "jpg", subdirectory: "Test Attachments")!
        let imageData = try Data(contentsOf: imageURL)
        let image = UIImage(data: imageData)!
        self.apptentive.sendAttachment(image)

        await #expect(self.backend.messageCenterCustomData == nil)
        guard case .inMemory = await self.backend.sentMessages[0].attachments.first?.storage else {
            throw TestError(reason: "Attachment has wrong storage type")
        }
    }

    @Test func sendDataAttachment() async throws {
        let imageURL = Bundle(for: BundleFinder.self).url(forResource: "dog", withExtension: "jpg", subdirectory: "Test Attachments")!
        let imageData = try Data(contentsOf: imageURL)
        self.apptentive.sendAttachment(imageData, mediaType: "image/jpeg")

        await #expect(self.backend.messageCenterCustomData == nil)
        guard case .inMemory(let data) = await self.backend.sentMessages[0].attachments.first?.storage else {
            throw TestError(reason: "Attachment has wrong storage type")
        }

        #expect(data == imageData)
    }

    @Test func testCanShowInteraction() async throws {
        let result = try await self.apptentive.canShowInteraction(event: "Test")

        #expect(result)
    }

    @Test func testCanShowInteractionWithCompletion() async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.apptentive.canShowInteraction(event: "Test") { result in
                continuation.resume(with: result)
            }
        }

        #expect(result)
    }

    @Test func testCanShowMessageCenter() async throws {
        let result = try await self.apptentive.canShowMessageCenter()

        #expect(result)
    }

    @Test func testCanShowMessageCenterWithCompletion() async throws {
        let result = try await withCheckedThrowingContinuation { continuation in
            self.apptentive.canShowMessageCenter { result in
                continuation.resume(with: result)
            }
        }

        #expect(result)
    }

    @Test func testValidLogIn() async throws {
        try await self.apptentive.logIn(with: "abc123")

        #expect(await self.backend.isLoggedIn)
    }

    @Test func testInvalidLogIn() async throws {
        await #expect(throws: ApptentiveError.authenticationFailed(reason: nil, responseString: nil)) {
            try await self.apptentive.logIn(with: "badtoken")
        }

        #expect(await !self.backend.isLoggedIn)
    }

    @Test func testValidLogInWithCompletion() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.apptentive.logIn(with: "abc123") { result in
                continuation.resume(with: result)
            }
        }

        #expect(await self.backend.isLoggedIn)
    }

    @Test func testInvalidLogInWithCompletion() async throws {
        await #expect(throws: ApptentiveError.authenticationFailed(reason: nil, responseString: nil)) {
            try await withCheckedThrowingContinuation { continuation in
                self.apptentive.logIn(with: "badtoken") { result in
                    continuation.resume(with: result)
                }
            }
        }

        #expect(await !self.backend.isLoggedIn)
    }

    @Test func testLogOut() async throws {
        try await self.apptentive.logIn(with: "abc123")

        #expect(await self.backend.isLoggedIn)

        try await self.apptentive.logOut()

        #expect(await !self.backend.isLoggedIn)
    }

    @Test func testLogOutWithCompletion() async throws {
        try await self.apptentive.logIn(with: "abc123")

        #expect(await self.backend.isLoggedIn)

        try await withCheckedThrowingContinuation { continuation in
            self.apptentive.logOut(completion: { result in
                continuation.resume(with: result)
            })
        }

        #expect(await !self.backend.isLoggedIn)
    }

    @Test func testLogOutFailureWithCompletion() async throws {
        await #expect(throws: ApptentiveError.notLoggedIn) {
            try await withCheckedThrowingContinuation { continuation in
                self.apptentive.logOut(completion: { result in
                    continuation.resume(with: result)
                })
            }
        }

        #expect(await !self.backend.isLoggedIn)
    }

    @Test func testUpdateToken() async throws {
        await #expect(self.backend.updatedToken == nil)

        try await self.apptentive.updateToken("def456")

        await #expect(self.backend.updatedToken == "def456")
    }

    @Test func testUpdateTokenWithCompletion() async throws {
        await #expect(self.backend.updatedToken == nil)

        try await withCheckedThrowingContinuation { continuation in
            self.apptentive.updateToken("def456") { result in
                continuation.resume(with: result)
            }
        }

        await #expect(self.backend.updatedToken == "def456")
    }

    @Test func testUpdateTokenFailureWithCompletion() async throws {
        await #expect(self.backend.updatedToken == nil)

        await #expect(throws: ApptentiveError.missingSubClaim) {
            try await withCheckedThrowingContinuation { continuation in
                self.apptentive.updateToken("abc123") { result in
                    continuation.resume(with: result)
                }
            }
        }

        await #expect(self.backend.updatedToken == nil)
    }

    @Test func testPersonUpdate() async throws {
        self.apptentive.personName = "Test Name"
        self.apptentive.personEmailAddress = "test@example.com"
        self.apptentive.personCustomData["string"] = "String"
        self.apptentive.mParticleID = "12345"

        try await withTimeout(seconds: 2) {
            while await self.backend.personName != "Test Name" {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
            }
        }

        #expect(await self.backend.personName == "Test Name")
        #expect(await self.backend.personEmailAddress == "test@example.com")
        #expect(await self.backend.personCustomData?["string"] as? String == "String")
        #expect(await self.backend.mParticleID == "12345")
    }

    @Test func testDeviceUpdate() async throws {
        self.apptentive.deviceCustomData["string"] = "String"

        try await withTimeout(seconds: 2) {
            while await self.backend.deviceCustomData?["string"] as? String == "String" {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
            }
        }

        #expect(await self.backend.deviceCustomData?["string"] as? String == "String")
    }

    @Test func testDistributionInfo() async throws {
        self.apptentive.distributionName = "Test Distro"
        self.apptentive.distributionVersion = "1.2.3"

        try await withTimeout(seconds: 2) {
            while await self.backend.distributionName == "Test Distro" {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
            }
        }

        #expect(await self.backend.distributionName == "Test Distro")
        #expect(await self.backend.distributionVersion == "1.2.3")
    }

    // MARK: Apptentive+Push

    @Test func testSetRemoteNotificationDeviceToken() async throws {
        let deviceTokenData = Data([0x01, 0x02, 0x03, 0x04, 0x05])

        self.apptentive.setRemoteNotificationDeviceToken(deviceTokenData)

        try await withTimeout(seconds: 2) {
            while await self.backend.tokenData == deviceTokenData {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
            }
        }

        #expect(await self.backend.tokenData == deviceTokenData)
    }

    @Test func testDidReceiveRemoteNotification() async throws {
        let nonApptentiveUserInfo: [AnyHashable: Any] = ["aps": ["alert": "Foo"]]

        let nonApptentiveResult = self.apptentive.didReceiveRemoteNotification(nonApptentiveUserInfo, fetchCompletionHandler: { _ in })

        #expect(!nonApptentiveResult)

        let apptentiveUserInfo: [AnyHashable: Any] = ["aps": ["content-available": true], "apptentive": ["alert": "Foo"]]

        await withCheckedContinuation { continuation in
            let result = self.apptentive.didReceiveRemoteNotification(
                apptentiveUserInfo,
                fetchCompletionHandler: { result in
                    #expect(result == .newData)
                    Task {
                        #expect(await self.environment.localNotificationTitle == "This Nifty App")
                        #expect(await self.environment.localNotificationBody == "Foo")
                        #expect(await self.environment.localNotificationUserInfo?["apptentive"] == ["alert": "Foo"])
                        // Can't test due to sendability of UNNotificationSound
                        // #expect(await self.environment.localNotificationSound != nil)

                        continuation.resume()
                    }
                })

            #expect(result)
        }

        let malformedUserInfo: [AnyHashable: Any] = ["aps": ["alert": "foo"], "apptentive": ["alert": "Foo"]]

        await withCheckedContinuation { continuation in
            let result = self.apptentive.didReceiveRemoteNotification(
                malformedUserInfo,
                fetchCompletionHandler: { result in
                    #expect(result == .newData)
                    continuation.resume()
                })

            #expect(result)
        }
    }

    // MARK: Apptentive+InteractionDelegate

    @Test func testSendSurveyResponse() async throws {
        let surveyResponse = SurveyResponse(
            surveyID: "abc123",
            questionResponses: [
                "def456": .answered([.choice("ghi789")])
            ])

        await self.apptentive.send(surveyResponse: surveyResponse)

        #expect(await self.backend.sentSurveyResponse == surveyResponse)
    }

    @Test func testEngageInteractionDelegate() async throws {
        // TODO: figure out how to call the InteractionDelegate version of engage here.
        // self.apptentive.engage(event: "Foo")
    }

    @Test func testRequestReview() async throws {
        let result = try await self.apptentive.requestReview()

        #expect(result)
    }

    @Test func testOpenURL() async throws {
        let result = await self.apptentive.open(URL(string: "https://example.com")!)

        #expect(result)
    }

    @Test func testInvoke() async throws {
        let invocation = EngagementManifest.Invocation(interactionID: "abc123", criteria: .init(subClauses: []))

        let result = try await self.apptentive.invoke([invocation])

        #expect(result == "foo")
    }

    @Test func testGetNextPageID() async throws {
        let advanceLogic = AdvanceLogic(criteria: .init(subClauses: []), pageID: "def456")

        let result = try await self.apptentive.getNextPageID(for: [advanceLogic])

        #expect(result == "bar")
    }

    @Test func testRecordResponse() async throws {
        let response = QuestionResponse.answered([.choice("abc123")])

        await self.apptentive.recordResponse(response, for: "def456")

        #expect(await self.backend.questionResponses["def456"] == response)
    }

    @Test func testSetResetCurrentResponse() async throws {
        let response = QuestionResponse.answered([.choice("abc123")])

        await self.apptentive.setCurrentResponse(response, for: "def456")

        #expect(await self.backend.currentResponses["def456"] == response)

        await self.backend.resetCurrentResponse(for: "def456")

        #expect(await self.backend.currentResponses["def456"] == nil)
    }

    @Test func testDraftMessageSending() async throws {
        await self.apptentive.setAutomatedMessageBody("Automated Message")

        await self.apptentive.setDraftMessageBody("Draft Message")

        let draftMessage = await self.apptentive.getDraftMessage()
        #expect(draftMessage.0.body == "Draft Message")

        try await self.apptentive.sendDraftMessage()

        #expect(await self.backend.sentMessages[0].body == "Automated Message")
        #expect(await self.backend.sentMessages[1].body == "Draft Message")
    }

    @Test func testGetMessages() async throws {
        let (messages, _) = await self.apptentive.getMessages()

        #expect(messages[0].nonce == "def456")
    }

    @Test func testSetMessageManagerDelegate() async throws {
        let messageManagerDelegate = MockMessagemanagerDelegate()

        await self.apptentive.setMessageManagerDelegate(messageManagerDelegate)

        #expect(await self.backend.messageManagerDelegate === messageManagerDelegate)
    }

    @Test func testAddDraftAttachmentURL() async throws {
        guard let environment = self.apptentive.environment as? MockEnvironment, let fileManager = environment.fileManager as? MockFileManager else {
            throw TestError(reason: "Expected MockEnvironment")
        }

        let attachmentURL = URL(fileURLWithPath: "/tmp/foo")
        fileManager.fileURLs.insert(attachmentURL)

        let result = try await self.apptentive.addDraftAttachment(url: attachmentURL)

        #expect(result.path == "/tmp")
        #expect(await self.backend.draftAttachment?.storage == .saved(path: attachmentURL.path))
    }

    @Test func testAddDraftAttachmentData() async throws {
        let attachmentData = Data([0, 1, 2, 3, 4])

        let result = try await self.apptentive.addDraftAttachment(data: attachmentData, name: "Dog.jpg", mediaType: "image/jpeg")

        #expect(result.path == "/tmp")
        #expect(await self.backend.draftAttachment?.storage == .inMemory(attachmentData))
        #expect(await self.backend.draftAttachment?.filename == "Dog.jpg")
        #expect(await self.backend.draftAttachment?.contentType == "image/jpeg")
    }

    @Test func removeDraftAttachment() async throws {
        let attachmentData = Data([0, 1, 2, 3, 4])

        let _ = try await self.apptentive.addDraftAttachment(data: attachmentData, name: "Dog.jpg", mediaType: "image/jpeg")

        #expect(await self.backend.draftAttachment != nil)

        try await self.apptentive.removeDraftAttachment(at: 0)

        #expect(await self.backend.draftAttachment == nil)
    }

    @Test func testLoadAttachment() async throws {
        let message = MessageList.Message(nonce: "abc123")
        let result = try await self.apptentive.loadAttachment(at: 0, in: message)

        #expect(result.path == "/tmp")
    }

    @Test func testMarkAsRead() async throws {
        try await self.apptentive.markMessageAsRead("123")
    }

    // MARK: EnvironmentDelegate

    @Test func testProtectedDataAvailable() async throws {
        // will be set to available by Apptentive initializer
        try await withTimeout(seconds: 2) {
            while await !self.backend.protectedDataAvailable {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
            }
        }

        let protectedDataAvailable = await backend.protectedDataAvailable
        #expect(protectedDataAvailable)

        self.apptentive.protectedDataWillBecomeUnavailable(self.apptentive.environment)

        try await withTimeout(seconds: 2) {
            while await self.backend.protectedDataAvailable {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
            }
        }

        self.apptentive.protectedDataDidBecomeAvailable(self.apptentive.environment)

        try await withTimeout(seconds: 2) {
            while await !self.backend.protectedDataAvailable {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 100)
            }
        }
    }

    @Test func testApplicationInForeground() {

        self.apptentive.protectedDataDidBecomeAvailable(self.apptentive.environment)
    }

    @Test func testApplicationWillEnterForeground() {
        self.apptentive.protectedDataDidBecomeAvailable(self.apptentive.environment)
    }

    @Test func testApplicationWillTerminate() {
        self.apptentive.applicationWillTerminate(self.apptentive.environment)
    }
}

actor SpyBackend: BackendProtocol {
    var delegate: (any ApptentiveKit.BackendDelegate & ApptentiveKit.MessageManagerApptentiveDelegate)?
    var appCredentials: ApptentiveKit.Apptentive.AppCredentials?
    var region: ApptentiveKit.Apptentive.Region?
    var connectionType: ApptentiveKit.Backend.ConnectionType? = .cached
    var engagedEvent: Event?
    var engagementResult: Bool = false
    var messageCenterCustomData: CustomData?
    var isLoggedIn: Bool = false
    var updatedToken: String?
    var tokenData: Data?
    var sentSurveyResponse: SurveyResponse?

    var validAppCredentials: Apptentive.AppCredentials = .init(key: "IOS-abc", signature: "123")
    var validToken = "abc123"
    var validTokenForUpdate = "def456"

    var payloadContext: Payload.Context = Payload.Context(tag: "tag", credentials: .embedded(id: "abc123"), encoder: JSONEncoder(), encryptionContext: .init(encryptionKey: Data(), embeddedToken: "def456"))

    func setDelegate(_ delegate: (any ApptentiveKit.BackendDelegate & ApptentiveKit.MessageManagerApptentiveDelegate)?) async {

    }

    func register(appCredentials: ApptentiveKit.Apptentive.AppCredentials, region: ApptentiveKit.Apptentive.Region) async throws -> ApptentiveKit.Backend.ConnectionType {
        guard appCredentials == validAppCredentials else {
            throw ApptentiveError.invalidAppCredentials
        }

        return .new
    }

    func engage(event: ApptentiveKit.Event) async throws -> Bool {
        self.engagedEvent = event

        return true
    }

    var personName: String?
    func setPersonName(_ personName: String?) {
        self.personName = personName
    }

    var personEmailAddress: String?
    func setPersonEmailAddress(_ personEmailAddress: String?) {
        self.personEmailAddress = personEmailAddress
    }

    var mParticleID: String?
    func setMParticleID(_ mParticleID: String?) {
        self.mParticleID = mParticleID
    }

    var personCustomData: CustomData?
    func setPersonCustomData(_ personCustomData: ApptentiveKit.CustomData) {
        self.personCustomData = personCustomData
    }

    var deviceCustomData: CustomData?
    func setDeviceCustomData(_ deviceCustomData: ApptentiveKit.CustomData) {
        self.deviceCustomData = deviceCustomData
    }

    var distributionVersion: String?
    func setDistributionVersion(_ distributionVersion: String?) {
        self.distributionVersion = distributionVersion
    }

    var distributionName: String?
    func setDistributionName(_ distributionName: String?) {
        self.distributionName = distributionName
    }

    func canShowInteraction(event: ApptentiveKit.Event) async throws -> Bool {
        return true
    }

    func logIn(with token: String) async throws {
        guard token == validToken else {
            throw ApptentiveError.authenticationFailed(reason: nil, responseString: nil)
        }

        self.isLoggedIn = true
    }

    func logOut() async throws {
        if !self.isLoggedIn {
            throw ApptentiveError.notLoggedIn
        }

        self.isLoggedIn = false
    }

    func updateToken(_ token: String) throws {
        guard token == self.validTokenForUpdate else {
            throw ApptentiveError.missingSubClaim
        }

        self.updatedToken = token
    }

    var sentMessages = [MessageList.Message]()
    func sendMessage(_ message: ApptentiveKit.MessageList.Message, with customData: ApptentiveKit.CustomData?) async throws {
        self.sentMessages.append(message)
        self.messageCenterCustomData = customData
    }

    func setMessageCenterCustomData(_ customData: ApptentiveKit.CustomData) async {
        self.messageCenterCustomData = customData
    }

    var messageManagerDelegate: MessageManagerDelegate?
    func setMessageManagerDelegate(_ delegate: (any ApptentiveKit.MessageManagerDelegate)?) async {
        self.messageManagerDelegate = delegate
    }

    var draftMessageBody: String?
    func setDraftMessageBody(_ body: String?) async {
        self.draftMessageBody = body
    }

    func getDraftMessage() async -> (ApptentiveKit.MessageList.Message, ApptentiveKit.MessageList.AttachmentContext?) {
        return (MessageList.Message.init(nonce: "abc123", body: self.draftMessageBody), nil)
    }

    var automatedMessageBody: String?
    func setAutomatedMessageBody(_ body: String?) async {
        self.automatedMessageBody = body
    }

    func prepareAutomatedMessageForSending() async throws -> ApptentiveKit.MessageList.Message? {
        return self.automatedMessageBody.flatMap { body in
            self.automatedMessageBody = nil

            return MessageList.Message.init(nonce: "def456", body: body)
        }
    }

    func prepareDraftMessageForSending() async throws -> (ApptentiveKit.MessageList.Message, ApptentiveKit.CustomData?) {
        let draftMessage = MessageList.Message.init(nonce: "abc123", body: self.draftMessageBody)
        self.draftMessageBody = nil

        return (draftMessage, nil)
    }

    var draftAttachment: MessageList.Message.Attachment?
    func addDraftAttachment(data: Data, name: String?, mediaType: String, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        self.draftAttachment = .init(contentType: mediaType, filename: name ?? "Image", storage: .inMemory(data))

        return URL(fileURLWithPath: "/tmp")
    }

    func addDraftAttachment(url: URL, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        self.draftAttachment = .init(contentType: "image/jpeg", filename: "Image", storage: .saved(path: url.path))

        return URL(fileURLWithPath: "/tmp")
    }

    func removeDraftAttachment(at index: Int) async throws {
        self.draftAttachment = nil
    }

    func loadAttachment(at index: Int, in message: ApptentiveKit.MessageList.Message, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        return URL(fileURLWithPath: "/tmp")
    }

    func url(for attachment: ApptentiveKit.MessageList.Message.Attachment) async -> URL? {
        return nil
    }

    func updateReadMessage(with messageNonce: String) async throws {

    }

    func getMessages() async -> [ApptentiveKit.MessageList.Message] {
        return [MessageList.Message.init(nonce: "def456")]
    }

    func getAttachmentContext() async -> ApptentiveKit.MessageList.AttachmentContext? {
        return nil
    }

    func send(surveyResponse: ApptentiveKit.SurveyResponse) async {
        self.sentSurveyResponse = surveyResponse
    }

    var invocations: [EngagementManifest.Invocation]?
    func invoke(_ invocations: [ApptentiveKit.EngagementManifest.Invocation]) async throws -> String {
        self.invocations = invocations

        return "foo"
    }

    var advanceLogic: [AdvanceLogic]?
    func getNextPageID(for advanceLogic: [ApptentiveKit.AdvanceLogic]) async throws -> String? {
        self.advanceLogic = advanceLogic

        return "bar"
    }

    var questionResponses = [String: QuestionResponse]()
    func recordResponse(_ response: ApptentiveKit.QuestionResponse, for questionID: String) {
        self.questionResponses[questionID] = response
    }

    var currentResponses = [String: QuestionResponse]()
    func setCurrentResponse(_ response: ApptentiveKit.QuestionResponse, for questionID: String) {
        self.currentResponses[questionID] = response
    }

    func resetCurrentResponse(for questionID: String) {
        self.currentResponses.removeValue(forKey: questionID)
    }

    func setRemoteNotificationDeviceToken(_ tokenData: Data) {
        self.tokenData = tokenData
    }

    func setMessageFetchCompletionHandler(_ messageFetchCompletion: (@Sendable (UIBackgroundFetchResult) -> Void)?) async {
        Task {
            messageFetchCompletion?(.newData)
        }
    }

    func setIsOverridingStyles() {

    }

    var protectedDataAvailable = false
    func protectedDataDidBecomeAvailable() {
        self.protectedDataAvailable = true
    }

    func protectedDataWillBecomeUnavailable() {
        self.protectedDataAvailable = false
    }

    var isInForeground = false
    func willEnterForeground() {
        self.isInForeground = true
    }

    func didEnterBackground() {
        self.isInForeground = false
    }

    func setLocalEngagementManifest(_ localEngagementManifest: ApptentiveKit.EngagementManifest?) {

    }

    func getInteractions() -> [ApptentiveKit.Interaction] {
        return []
    }

    func getInteraction(with id: String) -> ApptentiveKit.Interaction? {
        return nil
    }

    func getTargets() -> [String] {
        return []
    }

    func getState() -> ApptentiveKit.ConversationRoster.Record.State? {
        return .none
    }
}

class MockMessagemanagerDelegate: MessageManagerDelegate {
    func messageManagerMessagesDidChange(_ messageList: [ApptentiveKit.MessageList.Message], context: ApptentiveKit.MessageList.AttachmentContext?) {
    }

    func messageManagerDraftMessageDidChange(_ draftMessage: ApptentiveKit.MessageList.Message, context: ApptentiveKit.MessageList.AttachmentContext?) {
    }
}
