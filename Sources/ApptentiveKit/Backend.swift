//
//  Backend.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog
import UIKit

/// Protocol adopted by `Apptentive` for communication from backend to frontend.
@MainActor protocol BackendDelegate: AnyObject, Sendable {
    var interactionPresenter: InteractionPresenter { get }
    var resourceManager: ResourceManager { get }

    func authenticationDidFail(with error: Swift.Error)
    func setPrefetchContainerURL(_ prefetchContainerURL: URL?) async
    func prefetchResources(at: [URL]) async

    func updateProperties(with conversation: Conversation)
    func clearProperties()
}

protocol BackendProtocol: Actor {
    var payloadContext: Payload.Context { get }
    func setDelegate(_ delegate: (BackendDelegate & MessageManagerApptentiveDelegate)?) async

    func register(appCredentials: Apptentive.AppCredentials, region: Apptentive.Region) async throws -> Backend.ConnectionType
    @discardableResult func engage(event: Event) async throws -> Bool

    func setPersonName(_: String?)
    func setPersonEmailAddress(_: String?)
    func setMParticleID(_: String?)
    func setPersonCustomData(_: CustomData)
    func setDeviceCustomData(_: CustomData)
    func setDistributionVersion(_: String?)
    func setDistributionName(_: String?)

    func canShowInteraction(event: Event) async throws -> Bool
    func logIn(with token: String) async throws
    func logOut() async throws
    func updateToken(_ token: String) throws

    func sendMessage(_ message: MessageList.Message, with customData: CustomData?) async throws
    func setMessageCenterCustomData(_ customData: CustomData) async
    func setMessageFetchCompletionHandler(_ messageFetchCompletion: (@Sendable (UIBackgroundFetchResult) -> Void)?) async
    func setMessageManagerDelegate(_ delegate: MessageManagerDelegate?) async
    func setDraftMessageBody(_ body: String?) async
    func getDraftMessage() async -> (MessageList.Message, MessageList.AttachmentContext?)
    func setAutomatedMessageBody(_ body: String?) async
    func prepareAutomatedMessageForSending() async throws -> MessageList.Message?
    func prepareDraftMessageForSending() async throws -> (MessageList.Message, CustomData?)
    func addDraftAttachment(data: Data, name: String?, mediaType: String, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL
    func addDraftAttachment(url: URL, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL
    func removeDraftAttachment(at index: Int) async throws
    func loadAttachment(at index: Int, in message: MessageList.Message, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL
    func url(for attachment: MessageList.Message.Attachment) async -> URL?
    func updateReadMessage(with messageNonce: String) async throws
    func getMessages() async -> [MessageList.Message]
    func getAttachmentContext() async -> MessageList.AttachmentContext?

    func send(surveyResponse: SurveyResponse) async
    func invoke(_ invocations: [EngagementManifest.Invocation]) async throws -> String
    func getNextPageID(for advanceLogic: [AdvanceLogic]) async throws -> String?
    func recordResponse(_ response: QuestionResponse, for questionID: String)
    func setCurrentResponse(_ response: QuestionResponse, for questionID: String)
    func resetCurrentResponse(for questionID: String)

    func setRemoteNotificationDeviceToken(_ tokenData: Data)
    func setIsOverridingStyles()

    func protectedDataDidBecomeAvailable()
    func protectedDataWillBecomeUnavailable()
    func willEnterForeground()
    func didEnterBackground()

    func setLocalEngagementManifest(_ localEngagementManifest: EngagementManifest?)
    func getInteractions() -> [Interaction]
    func getInteraction(with id: String) -> Interaction?
    func getTargets() -> [String]
    func getState() -> ConversationRoster.Record.State?
}

/// The backend includes internal top-level methods used by the SDK.
///
/// It is implemented as a separate class from `Apptentive` to help enforce the main queue/background queue separation.
actor Backend: PayloadAuthenticationDelegate, BackendProtocol {

    /// The `Apptentive` instance that owns this `Backend` instance.
    private weak var delegate: BackendDelegate?

    /// Indicates the source of the conversation credentials when calling `connect(appCredentials:baseURL:completion:)`.
    enum ConnectionType {

        /// The conversation credentials were loaded from persistent storage.
        case cached

        /// The conversation credentials were retrieved from the API.
        case new
    }

    /// The primary persistent record of the state of the SDK.
    ///
    /// An temporary conversation object is created when the backend is initialized. When access to the device's
    /// persistent storage becomes available, any existing conversation is loaded and any newer data from
    /// the temporary conversation is merged into the saved conversation. This allows the SDK to function
    /// regardless of the order in which `load(containerURL:fileManager:)` and `connect(appCredentials:baseURL:completion:)`
    /// are called.
    private(set) var conversation: Conversation? {
        didSet {
            if self.conversation != oldValue {
                self.conversationNeedsSaving = true
            }
        }
    }

    var payloadContext: Payload.Context {
        switch (self.state.roster.active?.state, self.state.roster.active?.path) {
        case (.none, .none):
            return .init(tag: "loggedOut", credentials: .placeholder, sessionID: nil, encoder: self.jsonEncoder, encryptionContext: nil)

        case (.anonymous(let credentials), .some(let path)):
            return .init(tag: path, credentials: .header(id: credentials.id, token: credentials.token), sessionID: self.sessionID, encoder: self.jsonEncoder, encryptionContext: nil)

        case (.loggedIn(let credentials, _, let encryptionKey), .some(let path)):
            return .init(tag: path, credentials: .embedded(id: credentials.id), sessionID: self.sessionID, encoder: self.jsonEncoder, encryptionContext: .init(encryptionKey: encryptionKey, embeddedToken: credentials.token))

        default:
            return .init(tag: "placeholder", credentials: .placeholder, sessionID: self.sessionID, encoder: self.jsonEncoder, encryptionContext: nil)
        }
    }

    /// The object that determines whether an interaction should be presented when an event is engaged.
    let targeter: Targeter

    /// A Message Manager object which is initialized on launch.
    let messageManager: MessageManager

    /// The name of the Application Support subdirectory where Apptentive files are stored.
    let containerName: String

    /// Returns the URL to use for storing persistent files (in Application Support).
    var containerURL: URL {
        get throws {
            let parent = try self.fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return parent.appendingPathComponent(self.containerName)
        }
    }

    /// Returns the URL to use for storing cache files (may be removed by the system).
    var cacheURL: URL {
        get throws {
            let parent = try self.fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return parent.appendingPathComponent(self.containerName)
        }
    }

    /// The object implementing `HTTPRequesting` that should be used for HTTP requests.
    let requestor: HTTPRequesting

    /// Initializes a new backend instance.
    /// - Parameters:
    ///   - dataProvider: The `ConversationDataProviding` object used to initialize a new conversation.
    ///   - requestor: The `HTTPRequesting` object to use for making API requests.
    ///   - containerName: The name of the container directory in Application Support and Caches.
    init(dataProvider: ConversationDataProviding, requestor: HTTPRequesting, containerName: String) {
        let conversation = Conversation(dataProvider: dataProvider)
        let targeter = Targeter(engagementManifest: EngagementManifest.placeholder)
        let messageManager = MessageManager(notificationCenter: NotificationCenter.default)
        let requestRetrier = HTTPRequestRetrier()
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let roster = ConversationRoster(active: .init(state: .placeholder, path: "placeholder"), loggedOut: [])
        let state = BackendState(isInForeground: false, isProtectedDataAvailable: false, roster: roster, fatalError: false)
        let fileManager = FileManager.default

        self.init(
            conversation: conversation, state: state, containerName: containerName, targeter: targeter, requestor: requestor, messageManager: messageManager, requestRetrier: requestRetrier, payloadSender: payloadSender,
            dataProvider: dataProvider, fileManager: fileManager)
    }

    /// This initializer intended for testing only.
    /// - Parameters:
    ///   - conversation: The conversation that the backend should start with.
    ///   - state: The initial state of the backend object.
    ///   - containerName: The name of the container directory in Application Support and Caches.
    ///   - targeter: The targeter to use to determine if events should show an interaction.
    ///   - requestor: The `HTTPRequesting` object to use for making API requests.
    ///   - messageManager: The message manager to use to manage messages for Message Center.
    ///   - requestRetrier: The Apptentive API request retrier to use to send API requests.
    ///   - payloadSender: The payload sender to use to send updates to the API.
    ///   - dataProvider: The `ConversationDataProviding` object used to initialize new conversations.
    ///   - fileManager: A `FileManager` used to manipulate files.
    init(
        conversation: Conversation, state: BackendState, containerName: String, targeter: Targeter, requestor: HTTPRequesting, messageManager: MessageManager, requestRetrier: HTTPRequestRetrier, payloadSender: PayloadSending,
        dataProvider: ConversationDataProviding, fileManager: FileManager
    ) {
        self.conversation = conversation
        self.state = state
        self.containerName = containerName
        self.targeter = targeter
        self.requestor = requestor
        self.messageManager = messageManager
        self.requestRetrier = requestRetrier
        self.payloadSender = payloadSender
        self.dataProvider = dataProvider
        self.fileManager = fileManager
        self.jsonEncoder = JSONEncoder.apptentive

        Task {
            await self.payloadSender.setAuthenticationDelegate(self)
        }
        self.jsonEncoder.dateEncodingStrategy = .secondsSince1970
    }

    func setDelegate(_ delegate: (BackendDelegate & MessageManagerApptentiveDelegate)?) async {
        self.delegate = delegate
        await self.messageManager.setApptentiveDelegate(delegate)
    }

    /// Connects the backend to the Apptentive API.
    /// - Parameters:
    ///   - appCredentials: The App Key and App Signature to use when communicating with the Apptentive API
    ///   - region: A `Region` object specifying the server to use for API requests.
    /// - Returns: A value that indicates whether the connection is new or cached.
    /// - Throws: An error if registration fails.
    func register(appCredentials: Apptentive.AppCredentials, region: Apptentive.Region) async throws -> ConnectionType {
        let client = HTTPClient(requestor: self.requestor, baseURL: region.apiBaseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: self.dataProvider.sdkVersion), languageCode: self.dataProvider.preferredLocalization)
        await self.requestRetrier.setClient(client)
        await self.payloadSender.setAppCredentials(appCredentials)

        let result = try await withCheckedThrowingContinuation { continuation in
            self.registerContinuation = continuation

            self.state.appCredentials = appCredentials
        }

        return result
    }

    /// Sets up access to persistent storage and loads any previously-saved conversation data if needed.
    ///
    /// This method may be called multiple times if the device is locked with the app in the foreground and then unlocked.
    /// - Throws: An error if the conversation file exists but can't be read, or if the saved conversation can't be merged with the in-memory conversation.
    func protectedDataDidBecomeAvailable() {
        self.state.isProtectedDataAvailable = true
    }

    /// Reliquishes access to persistent storage.
    ///
    /// Called when the device is locked with the app in the foreground.
    func protectedDataWillBecomeUnavailable() {
        self.state.isProtectedDataAvailable = false
    }

    func willEnterForeground() {
        self.state.isInForeground = true
    }

    func didEnterBackground() {
        self.state.isInForeground = false
    }

    func invalidateEngagementManifestForDebug() {
        if self.dataProvider.isDebugBuild {
            self.invalidateEngagementManifest()
        }
    }

    func invalidateEngagementManifest() {
        self.targeter.engagementManifest.expiry = .distantPast
    }

    // MARK: Payload Authentication Delegate

    var appCredentials: Apptentive.AppCredentials? {
        return self.state.appCredentials
    }

    nonisolated func authenticationDidFail(with response: ErrorResponse?) {
        Task { @MainActor in
            let delegate = await self.delegate

            delegate?.authenticationDidFail(with: ApptentiveError.authenticationFailed(reason: response?.errorType, responseString: response?.error))
        }
    }

    // MARK: - Methods/Properties accessed by Apptentive object

    func setPersonName(_ personName: String?) {
        self.conversation?.person.name = personName
    }

    func setPersonEmailAddress(_ personEmailAddress: String?) {
        self.conversation?.person.emailAddress = personEmailAddress
    }

    func setMParticleID(_ mParticleID: String?) {
        self.conversation?.person.mParticleID = mParticleID
    }

    func setPersonCustomData(_ personCustomData: CustomData) {
        self.conversation?.person.customData = personCustomData
    }

    func setDeviceCustomData(_ deviceCustomData: CustomData) {
        self.conversation?.device.customData = deviceCustomData
    }

    func setDistributionName(_ distributionName: String?) {
        self.conversation?.appRelease.sdkDistributionName = distributionName
        self.dataProvider.distributionName = distributionName
    }

    func setDistributionVersion(_ distributionVersion: String?) {
        self.conversation?.appRelease.sdkDistributionVersion = distributionVersion.flatMap { Version(string: $0) }
        self.dataProvider.distributionVersion = distributionVersion.flatMap { Version(string: $0) }
    }

    func setRemoteNotificationDeviceToken(_ tokenData: Data) {
        self.conversation?.device.remoteNotificationDeviceToken = tokenData
        self.dataProvider.remoteNotificationDeviceToken = tokenData
    }

    func setIsOverridingStyles() {
        self.conversation?.appRelease.isOverridingStyles = true
        self.dataProvider.isOverridingStyles = true
    }

    /// Engages an event.
    ///
    /// This consists of the following steps:
    /// 1. Sends an API request to create the event on the server.
    /// 2. Increments the relevant engagement metric in the conversation.
    /// 3. Presents an interaction if one was triggered by the event being engaged.
    /// - Parameter event: The `Event` object to be engaged.
    /// - Returns: A boolean that indicates whether engaging the event resulted in the presentation of an interaction.
    /// - Throws: An error if engaging the event fails.
    @discardableResult func engage(event: Event) async throws -> Bool {
        Logger.engagement.info("Engaged event “\(event.codePointName)”")

        if self.conversation == nil {
            Logger.engagement.info("No active conversation (logged out).")
        }

        do {
            try await self.payloadSender.send(Payload(wrapping: event, with: self.payloadContext), persistEagerly: false)
        } catch let error {
            Logger.default.error("Unable to enqueue event payload: \(error).")
        }

        self.conversation?.codePoints.increment(for: event.codePointName)

        if let conversation = self.conversation, let interaction = try self.targeter.interactionData(for: event, state: conversation) {
            try await self.presentInteraction(interaction)
            return true
        } else {
            return false
        }
    }

    /// Sends a survey response to the Apptentive API.
    /// - Parameter surveyResponse: The survey response to send to the API.
    func send(surveyResponse: SurveyResponse) async {
        do {
            try await self.payloadSender.send(Payload(wrapping: surveyResponse, with: self.payloadContext), persistEagerly: true)
        } catch let error {
            Logger.default.error("Unable to enqueue survey response payload: \(error).")
        }
    }

    /// Evaluates a list of invocations and presents an interaction, if needed.
    /// - Parameter invocations: The invocations to evaluate.
    /// - Returns: The ID of the invoked interaction, if any.
    /// - Throws: An error if invoking the invocation fails.
    func invoke(_ invocations: [EngagementManifest.Invocation]) async throws -> String {
        guard let conversation = self.conversation else {
            throw ApptentiveError.noActiveConversation
        }

        guard let destinationInteraction = try self.targeter.interactionData(for: invocations, state: conversation) else {
            throw ApptentiveError.internalInconsistency
        }

        try await self.presentInteraction(destinationInteraction)

        return destinationInteraction.id
    }

    /// Gets the identifier for the next page, if any, by evaluating the specified advance logic.
    /// - Parameter advanceLogic: The advance logic to evaluate.
    /// - Returns: The page ID to which to advance.
    /// - Throws: An error if evaluating the logic fails.
    func getNextPageID(for advanceLogic: [AdvanceLogic]) async throws -> String? {
        guard let conversation = self.conversation else {
            throw ApptentiveError.noActiveConversation
        }

        for item in advanceLogic {
            if try item.criteria.isSatisfied(for: conversation) {
                return item.pageID
            }
        }

        return nil
    }

    /// Records a response to an interaction for use later in targeting.
    /// - Parameters:
    ///   - response: The response to the question.
    ///   - questionID: The identifier associated with the question or note.
    func recordResponse(_ response: QuestionResponse, for questionID: String) {
        self.conversation?.interactions.record(response, for: questionID)
    }

    /// Records a response to an interaction for use in immediate branching.
    /// - Parameters:
    ///   - response: The response to the question.
    ///   - questionID: The identifier associated with the question or note.
    func setCurrentResponse(_ response: QuestionResponse, for questionID: String) {
        self.conversation?.interactions.setLastResponse(response, for: questionID)
    }

    /// Records the that interaction with the specified ID requested a response.
    /// - Parameter questionID: The identifier associated with the question or note.
    func resetCurrentResponse(for questionID: String) {
        self.conversation?.interactions.resetCurrentResponse(for: questionID)
    }

    /// Queues the specified message to be sent by the payload sender.
    ///
    /// If custom data was set when Message Center was presented,
    /// the custom data is attached to the message (and removed
    /// so that it won't be attached again to future messages).
    /// - Parameters:
    ///   - message: The message to send.
    ///   - customData: The custom data to attach to the message.
    /// - Throws: An error if the message can't be sent.
    func sendMessage(_ message: MessageList.Message, with customData: CustomData? = nil) async throws {
        guard let attachmentManager = await self.messageManager.attachmentManager else {
            throw ApptentiveError.internalInconsistency
        }

        let payload = try Payload(wrapping: message, with: self.payloadContext, customData: customData, attachmentURLProvider: attachmentManager)

        await self.payloadSender.send(payload, persistEagerly: true)

        await self.messageManager.addQueuedMessage(message, with: payload.identifier)
    }

    /// Sets a completion handler that is called when a message fetch completes.
    func setMessageFetchCompletionHandler(_ messageFetchCompletion: (@Sendable (UIBackgroundFetchResult) -> Void)?) async {
        self.messageFetchCompletion = messageFetchCompletion

        if let anonymousCredentials = self.state.anonymousCredentials, self.messageFetchCompletion != nil {
            await self.messageManager.setForceMessageDownload()

            self.getMessagesIfNeeded(with: anonymousCredentials)
        }
    }

    func setMessageCenterCustomData(_ customData: CustomData) async {
        await self.messageManager.setCustomData(customData)
    }

    func setMessageManagerDelegate(_ delegate: MessageManagerDelegate?) async {
        await self.messageManager.setDelegate(delegate)
    }

    func setDraftMessageBody(_ body: String?) async {
        await self.messageManager.setDraftMessageBody(body)
    }

    func getDraftMessage() async -> (MessageList.Message, MessageList.AttachmentContext?) {
        return await (self.messageManager.draftMessage, self.messageManager.attachmentContext)
    }

    func setAutomatedMessageBody(_ body: String?) async {
        await self.messageManager.setAutomatedMessageBody(body)
    }

    func prepareAutomatedMessageForSending() async throws -> MessageList.Message? {
        return try await self.messageManager.prepareAutomatedMessageForSending()
    }

    func prepareDraftMessageForSending() async throws -> (MessageList.Message, CustomData?) {
        return try await self.messageManager.prepareDraftMessageForSending()
    }

    func addDraftAttachment(data: Data, name: String?, mediaType: String, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        return try await self.messageManager.addDraftAttachment(data: data, name: name, mediaType: mediaType, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
    }

    func addDraftAttachment(url: URL, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        return try await self.messageManager.addDraftAttachment(url: url, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
    }

    func removeDraftAttachment(at index: Int) async throws {
        try await self.messageManager.removeDraftAttachment(at: index)
    }

    func loadAttachment(at index: Int, in message: MessageList.Message, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        return try await self.messageManager.loadAttachment(at: index, in: message, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
    }

    func url(for attachment: MessageList.Message.Attachment) async -> URL? {
        return await self.messageManager.attachmentManager?.url(for: attachment)
    }

    func updateReadMessage(with messageNonce: String) async throws {
        try await self.messageManager.updateReadMessage(with: messageNonce)
    }

    func getMessages() async -> [MessageList.Message] {
        return await self.messageManager.messages
    }

    func getAttachmentContext() async -> MessageList.AttachmentContext? {
        return await self.messageManager.attachmentContext
    }

    /// Checks if the event can trigger an interaction.
    /// - Parameters:
    ///  - event: The event used to check if it can trigger an interaction.
    ///  - completion: A completion handler that is called with a boolean indicating whether or not an interaction can be shown using the event.
    func canShowInteraction(event: Event) async throws -> Bool {
        guard let conversation = self.conversation else {
            throw ApptentiveError.noActiveConversation
        }

        let result = try self.targeter.interactionData(for: event, state: conversation)
        return result != nil
    }

    func logIn(with token: String) async throws {
        guard let jwtSubject = try JWT(string: token).payload.subject else {
            throw ApptentiveError.missingSubClaim
        }

        guard let appCredentials = self.state.appCredentials else {
            throw ApptentiveError.loginCalledBeforeRegister
        }

        let activeConversationState = self.state.roster.active?.state
        let loggedOutConversationID = self.state.roster.loggedOutRecord(with: jwtSubject)?.id

        switch (activeConversationState, loggedOutConversationID) {
        case (.none, .some(let id)):
            Logger.default.debug("Logging in logged-out conversation with subject \(jwtSubject) and id \(id).")

            let sessionResponse = try await self.resumeSession(with: AnonymousAPICredentials(appCredentials: appCredentials, conversationCredentials: .init(id: id, token: token)))
            try self.state.roster.logInLoggedOutRecord(with: jwtSubject, token: token, encryptionKey: sessionResponse.encryptionKey)
            try self.saveRoster(self.state.roster)

        case (.none, .none):
            Logger.default.debug("Logging in new conversation with subject \(jwtSubject).")

            let conversation = Conversation(dataProvider: dataProvider)
            let conversationResponse = try await self.postConversation(conversation, with: PendingAPICredentials(appCredentials: appCredentials), token: token)
            self.lastSyncedConversation = conversation
            try self.state.roster.createLoggedInRecord(with: jwtSubject, id: conversationResponse.id, token: token, encryptionKey: conversationResponse.encryptionKey)
            try self.saveRoster(self.state.roster)

        case (.anonymous(credentials: let conversationCredentials), .none):
            Logger.default.debug("Authenticating anonymous conversation with identifier \(conversationCredentials.id) using subject \(jwtSubject).")

            let sessionResponse = try await self.resumeSession(with: AnonymousAPICredentials(appCredentials: appCredentials, conversationCredentials: .init(id: conversationCredentials.id, token: token)))
            try self.state.roster.logInAnonymousRecord(with: jwtSubject, token: token, encryptionKey: sessionResponse.encryptionKey)
            try self.saveRoster(self.state.roster)

        case (.anonymousPending, _), (.placeholder, _):
            throw ApptentiveError.activeConversationPending

        case (.loggedIn(credentials: let credentials, subject: let subject, encryptionKey: _), _):
            throw ApptentiveError.alreadyLoggedIn(subject: subject, id: credentials.id)

        default:
            throw ApptentiveError.internalInconsistency
        }
    }

    func logOut() async throws {
        await self.requestRetrier.cancel(identifier: "log in new conversation")
        await self.requestRetrier.cancel(identifier: "resume session")

        guard case .loggedIn(credentials: let credentials, subject: let subject, encryptionKey: _) = self.state.roster.active?.state else {
            throw ApptentiveError.notLoggedIn
        }

        Logger.default.debug("Logging out conversation with subject \(subject) and id \(credentials.id).")

        try await self.engage(event: .logout)
        try await self.payloadSender.send(.logout(with: self.payloadContext), persistEagerly: true)
        try self.state.roster.logOutActiveConversation()
        try self.saveRoster(self.state.roster)
    }

    func updateToken(_ token: String) throws {
        guard let jwtSubject = try JWT(string: token).payload.subject else {
            throw ApptentiveError.missingSubClaim
        }

        Logger.default.debug("Updating JWT for logged-in conversation with subject \(jwtSubject).")
        try self.state.roster.updateLoggedInRecord(with: token, matching: jwtSubject)
        try self.saveRoster(self.state.roster)
    }

    private func startAnonymousConversation(with credentials: PendingAPICredentials) async throws {
        guard let conversation = self.conversation else {
            throw ApptentiveError.internalInconsistency
        }

        Logger.default.debug("Registering new anonymous conversation.")
        let postedConversation = conversation
        let conversationResponse = try await self.postConversation(conversation, with: credentials)
        self.lastSyncedConversation = postedConversation
        try self.state.roster.registerAnonymousRecord(with: conversationResponse.id, token: conversationResponse.token)
        try self.saveRoster(self.state.roster)
    }

    private(set) var state: BackendState {
        didSet {
            if self.state.summary != oldValue.summary {
                Task {
                    await self.handleTransition((from: oldValue.summary, to: self.state.summary))
                }
            }
        }
    }

    // MARK: - Private

    private var sessionID: String?

    private let jsonEncoder: JSONEncoder

    private let requestRetrier: HTTPRequestRetrier

    private let payloadSender: PayloadSending

    private var dataProvider: ConversationDataProviding

    private var fileManager: FileManager

    private var configuration: Configuration? {
        didSet {
            if let configuration = self.configuration {
                Task {
                    await self.messageManager.setPollingIntervals(
                        foreground: configuration.messageCenter.foregroundPollingInterval,
                        background: configuration.messageCenter.backgroundPollingInterval)
                }
            }
        }
    }

    /// The saver used to save the conversation roster to persistent storage.
    private var rosterSaver: PropertyListSaver<ConversationRoster>?

    /// The saver used to save the conversation to persistent storage.
    private var conversationSaver: EncryptedPropertyListSaver<Conversation>?

    /// Whether the conversation has changes that need to be saved to persistent storage.
    private var conversationNeedsSaving: Bool = false

    /// A repeating task that periodically runs a task to save the conversation and payload sender.
    private var housekeepingTask: Task<Void, Error>?

    /// The version of the conversation that was last sent to the API.
    private var lastSyncedConversation: Conversation?

    private var registerContinuation: CheckedContinuation<ConnectionType, Error>?

    private var messageFetchCompletion: ((UIBackgroundFetchResult) -> Void)?

    private func handleTransition(_ transition: (from: BackendState.Summary, to: BackendState.Summary)) async {
        Logger.default.debug("Backend state transition \(String(describing: transition))")

        do {
            if transition.to == .waiting {
                return
            }

            let containerURL = try self.containerURL
            let cacheURL = try self.cacheURL

            switch transition {
            case (from: .waiting, to: .loading(let appCredentials)), (from: .backgrounded, to: .loading(let appCredentials)):
                try await self.createCommonSavers(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials)
                let roster = try await self.loadCommonFiles(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials)

                if let activeRecord = roster.active {
                    try await self.createRecordSavers(for: activeRecord, containerURL: containerURL)
                    try self.loadRecordFiles(for: activeRecord, containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials)
                    self.syncFrontendVariables()
                }

                self.state.roster = roster

            case (from: .loading, to: .posting(let pendingCredentials)):
                try await self.startAnonymousConversation(with: pendingCredentials)

            case (from: .posting, to: .anonymous(let payloadCredentials)):
                try await self.startSession()

                self.registerContinuation?.resume(returning: .new)
                self.registerContinuation = nil

                try await self.payloadSender.updateCredentials(payloadCredentials, for: "placeholder", encryptionContext: nil)
                self.startHousekeepingTask()

            case (from: .loading, to: .anonymous(let payloadCredentials)):
                try await self.startSession()

                self.registerContinuation?.resume(returning: .cached)
                self.registerContinuation = nil

                try await self.payloadSender.updateCredentials(payloadCredentials, for: "placeholder", encryptionContext: nil)
                self.startHousekeepingTask()

            case (from: .loading, to: .loggedIn(let payloadCredentials, let encryptionContext)):
                self.registerContinuation?.resume(returning: .cached)
                self.registerContinuation = nil
                try await self.startSession()
                self.syncFrontendVariables()

                try await self.payloadSender.updateCredentials(payloadCredentials, for: "placeholder", encryptionContext: encryptionContext)
                self.startHousekeepingTask()

            case (from: .loading, to: .loggedOut):
                self.conversation = nil
                self.clearFrontendVariables()
                self.registerContinuation?.resume(returning: .cached)
                self.registerContinuation = nil

            case (from: .anonymous, to: .loggedIn(let payloadCredentials, let encryptionContext)):
                guard let activeRecord = self.state.roster.active else {
                    throw ApptentiveError.internalInconsistency
                }

                try await self.createRecordSavers(for: activeRecord, containerURL: containerURL)
                try self.saveConversation()
                try await self.messageManager.saveMessages()
                try self.removePlaintextFiles(in: containerURL, for: activeRecord)
                try await self.payloadSender.updateCredentials(payloadCredentials, for: activeRecord.path, encryptionContext: encryptionContext)
                try await self.engage(event: .login)

            case (from: .loggedOut, to: .loggedIn):
                guard let activeRecord = self.state.roster.active, let appCredentials = self.state.appCredentials else {
                    throw ApptentiveError.internalInconsistency
                }

                try await self.createRecordSavers(for: activeRecord, containerURL: containerURL)
                try self.loadRecordFiles(for: activeRecord, containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials)
                self.startHousekeepingTask()

                try await self.startSession()
                self.syncFrontendVariables()
                try await self.engage(event: .login)

            case (from: .loggedIn, to: .loggedOut):
                self.cancelHousekeepingTask()
                self.conversation = nil
                self.clearFrontendVariables()
                try await self.messageManager.deleteCachedMessages()
                self.invalidateEngagementManifest()

            case (from: .loggedIn, to: .loggedIn(let payloadCredentials, let encryptionContext)):  // Conversation credentials were updated.
                guard let activeRecord = self.state.roster.active else {
                    throw ApptentiveError.internalInconsistency
                }

                try await self.payloadSender.updateCredentials(payloadCredentials, for: activeRecord.path, encryptionContext: encryptionContext)

            case (from: .backgrounded, to: .anonymous), (from: .backgrounded, to: .loggedIn):
                try await self.startSession()
                await self.payloadSender.resume()
                self.startHousekeepingTask()

            case (from: .anonymous, to: .backgrounded), (from: .loggedIn, to: .backgrounded):
                await self.startBackgroundTask()
                try await self.endSession()

                await self.syncConversationWithAPI()

                await self.payloadSender.drain()
                await self.endBackgroundTask()

                self.cancelHousekeepingTask()
                try await self.saveToPersistentStorageIfNeeded()

            case (from: _, to: .backgrounded):
                break  // Allowed state transition, no action.

            case (from: .backgrounded, to: _):
                try await self.unlockIfNeeded()

            case (from: .locked, to: _):
                try await self.unlockIfNeeded()

            case (from: _, to: .locked):
                self.cancelHousekeepingTask()
                await self.destroySavers()

            default:
                throw ApptentiveError.unsupportedBackendStateTransition
            }
        } catch let error {
            if let registerContinuation = self.registerContinuation {
                registerContinuation.resume(throwing: error)
                self.registerContinuation = nil
            } else {
                apptentiveCriticalError("Error during state transition (from \(transition.from) to \(transition.to): \(error). Suspending SDK operation until next cold launch.")
            }
            self.state.fatalError = true
        }
    }

    private func startSession() async throws {
        self.sessionID = UUID().uuidString
        self.invalidateEngagementManifestForDebug()
        await self.messageManager.setForceMessageDownload()
        await self.requestRetrier.resetRetryDelay()
        try await self.engage(event: .launch())
    }

    private func endSession() async throws {
        try await self.engage(event: .exit())
        self.sessionID = nil
    }

    private func unlockIfNeeded() async throws {
        if let appCredentials = self.state.appCredentials, state.isProtectedDataAvailable, self.rosterSaver == nil {
            try await self.createCommonSavers(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials)

            if let activeRecord = self.state.roster.active {
                try await self.createRecordSavers(for: activeRecord, containerURL: containerURL)
            }
        }
    }

    @MainActor private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?

    @MainActor private func startBackgroundTask() {
        #if canImport(UIKit)
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "com.apptentive.feedback") {
                self.endBackgroundTask()
            }

            Logger.default.debug("Started background task with ID \(String(describing: self.backgroundTaskIdentifier)).")
        #endif
    }

    @MainActor private func endBackgroundTask() {
        guard let backgroundTaskIdentifier = self.backgroundTaskIdentifier else {
            return apptentiveCriticalError("Expected to have background task identifier.")
        }

        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
        Logger.default.debug("Ended background task with ID \(String(describing: self.backgroundTaskIdentifier)).")
    }

    private func createCommonSavers(containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials) async throws {
        self.rosterSaver = PropertyListSaver<ConversationRoster>(containerURL: containerURL, filename: CurrentLoader.rosterFilename(for: appCredentials), fileManager: self.fileManager)
        await self.payloadSender.makeSaver(containerURL: containerURL, filename: CurrentLoader.payloadsFilename(for: appCredentials))
        await self.messageManager.setAttachmentManager(AttachmentManager(requestor: URLSession.shared, cacheContainerURL: cacheURL, savedContainerURL: containerURL))
    }

    private func loadCommonFiles(containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials) async throws -> ConversationRoster {
        let context = LoaderContext(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        let result = try CurrentLoader.loadLatestVersion(context: context) { loader in
            let roster = try loader.loadRoster()
            Task {
                try await self.payloadSender.load(from: loader)

                // Save any data that might have been migrated
                try self.saveRoster(roster)
                try await self.payloadSender.savePayloadsIfNeeded()
            }
            return roster
        }

        await self.delegate?.setPrefetchContainerURL(containerURL.appendingPathComponent(CurrentLoader.resourceDirectoryName(for: appCredentials)))

        return result
    }

    private func createRecordSavers(for record: ConversationRoster.Record, containerURL: URL) async throws {
        let recordContainerURL = containerURL.appendingPathComponent(record.path)
        self.conversationSaver = EncryptedPropertyListSaver<Conversation>(containerURL: recordContainerURL, filename: CurrentLoader.conversationFilename, fileManager: self.fileManager, encryptionKey: record.encryptionKey)
        await self.messageManager.makeSaver(containerURL: recordContainerURL, filename: CurrentLoader.messagesFilename, encryptionKey: record.encryptionKey)
    }

    private func loadRecordFiles(for activeRecord: ConversationRoster.Record, containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials) throws {
        let context = LoaderContext(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, dataProvider: self.dataProvider, fileManager: self.fileManager)

        try CurrentLoader.loadLatestVersion(for: activeRecord, context: context) { loader in
            try self.loadConversation(from: loader, for: activeRecord)
            try self.saveConversationIfNeeded()

            Task {
                try await self.messageManager.load(from: loader, for: activeRecord)
                try await self.messageManager.saveMessagesIfNeeded()
            }
        }
    }

    private func removePlaintextFiles(in containerURL: URL, for activeRecord: ConversationRoster.Record) throws {
        let plaintextConversationFileURL = containerURL.appendingPathComponent(CurrentLoader.conversationFilePath(for: activeRecord))
        if self.fileManager.fileExists(atPath: plaintextConversationFileURL.path) {
            try self.fileManager.removeItem(at: plaintextConversationFileURL)
        }

        let plaintextMessageListFileURL = containerURL.appendingPathComponent(CurrentLoader.messagesFilePath(for: activeRecord))
        if self.fileManager.fileExists(atPath: plaintextMessageListFileURL.path) {
            try self.fileManager.removeItem(at: plaintextMessageListFileURL)
        }
    }

    private func destroySavers() async {
        await self.messageManager.setAttachmentManager(nil)
        await self.messageManager.destroySaver()
        await self.payloadSender.destroySaver()
        self.conversationSaver = nil
        self.rosterSaver = nil
        await self.delegate?.setPrefetchContainerURL(nil)
    }

    /// Loads the conversation using the specified loader.
    /// - Parameters:
    ///  - loader: The loader that translates the stored conversation to the current format, if needed.
    ///  - record: The record for which to load the conversation data.
    /// - Throws: An error if loading or merging the conversation fails.
    private func loadConversation(from loader: Loader, for record: ConversationRoster.Record) throws {
        let previousConversation = try loader.loadConversation(for: record)

        self.lastSyncedConversation = previousConversation

        if let placeholderConversation = self.conversation {
            self.conversation = try previousConversation.merged(with: placeholderConversation)
        } else {
            self.conversation = previousConversation
        }

        if self.conversation != previousConversation {
            self.conversationNeedsSaving = true
        }

        try self.saveConversationIfNeeded()
    }

    private func presentInteraction(_ interaction: Interaction) async throws {
        guard let delegate = self.delegate else {
            throw ApptentiveError.internalInconsistency
        }

        try await delegate.interactionPresenter.presentInteraction(interaction)
        self.incrementInteractionMetric(for: interaction)
    }

    private func incrementInteractionMetric(for interaction: Interaction) {
        self.conversation?.interactions.increment(for: interaction.id)
    }

    // MARK: API syncing

    /// If registered, sends updates to person, device, and app release if they have changed since the last sync.
    ///
    /// Would be private but needs to be internal for testing.
    internal func syncConversationWithAPI() async {
        guard let conversation = self.conversation else {
            Logger.network.debug("Skipping API sync: No active conversation.")
            return
        }

        guard let credentials = self.state.anonymousCredentials else {
            Logger.network.debug("Skipping API sync: Not yet registered.")
            return
        }

        guard let lastSyncedConversation = self.lastSyncedConversation else {
            Logger.network.debug("Skipping API sync: No previously synced conversation.")
            return
        }

        self.getInteractionsIfNeeded(with: credentials)

        self.getConfigurationIfNeeded(with: credentials)

        self.getMessagesIfNeeded(with: credentials)

        if AppReleaseContent(with: lastSyncedConversation.appRelease) != AppReleaseContent(with: conversation.appRelease) {
            Logger.network.debug("App release data changed. Enqueueing update.")
            do {
                try await self.payloadSender.send(Payload(wrapping: conversation.appRelease, with: self.payloadContext), persistEagerly: false)
                self.lastSyncedConversation?.appRelease = conversation.appRelease
            } catch let error {
                Logger.default.error("Unable to enqueue app release payload: \(error).")
            }
        }

        if PersonContent(with: lastSyncedConversation.person) != PersonContent(with: conversation.person) {
            Logger.network.debug("Person data changed. Enqueueing update.")
            do {
                try await self.payloadSender.send(Payload(wrapping: conversation.person, with: self.payloadContext), persistEagerly: false)
                self.lastSyncedConversation?.person = conversation.person
            } catch let error {
                Logger.default.error("Unable to enqueue person payload: \(error).")
            }
        }

        if DeviceContent(with: lastSyncedConversation.device) != DeviceContent(with: conversation.device) {
            Logger.network.debug("Device data changed. Enqueueing update.")
            do {
                try await self.payloadSender.send(Payload(wrapping: conversation.device, with: self.payloadContext), persistEagerly: false)

                if lastSyncedConversation.device.localeRaw != conversation.device.localeRaw {
                    Logger.engagement.debug("Locale changed. Invalidating engagement manifest.")
                    self.invalidateEngagementManifest()
                }

                self.lastSyncedConversation?.device = conversation.device
            } catch let error {
                Logger.default.error("Unable to enqueue device payload: \(error).")
            }
        }
    }

    // MARK: Persistence

    /// Saves the conversation and payload queue to persistent storage if needed.
    ///
    /// Would be private but needs to be internal for testing.
    internal func saveToPersistentStorageIfNeeded() async throws {
        try self.saveConversationIfNeeded()
        try await self.payloadSender.savePayloadsIfNeeded()
        try await self.messageManager.saveMessagesIfNeeded()
    }

    /// Saves the conversation roster to persistent storage.
    ///
    /// Would be private but needs to be internal for testing.
    /// - Throws: An error if the saver is nil.
    internal func saveRoster(_ roster: ConversationRoster) throws {
        guard let saver = self.rosterSaver else {
            throw ApptentiveError.internalInconsistency
        }

        try saver.save(roster)
    }

    /// Saves the conversation to persistent storage if marked as dirty.
    private func saveConversationIfNeeded() throws {
        if self.conversationNeedsSaving {
            try self.saveConversation()
        }
    }

    /// Saves the conversation to persistent storage.
    private func saveConversation() throws {
        if let saver = self.conversationSaver, let conversation = self.conversation {
            try saver.save(conversation)
            self.conversationNeedsSaving = false
        }
    }

    // MARK: Housekeeping timer

    private func startHousekeepingTask() {
        if self.housekeepingTask == nil {
            self.housekeepingTask = Task {
                repeat {
                    Logger.default.debug("Running periodic housekeeping task")
                    await self.syncConversationWithAPI()
                    try? await self.saveToPersistentStorageIfNeeded()

                    try? await Task.sleep(nanoseconds: 10 * NSEC_PER_SEC)
                } while !Task.isCancelled

                self.housekeepingTask = nil
            }
        }
    }

    private func cancelHousekeepingTask() {
        self.housekeepingTask?.cancel()
    }

    // MARK: - Frontend

    func syncFrontendVariables() {
        guard let conversation = self.conversation, let delegate = self.delegate else {
            return
        }

        DispatchQueue.main.async {
            delegate.updateProperties(with: conversation)
        }
    }

    func clearFrontendVariables() {
        guard let delegate = self.delegate else {
            return
        }

        DispatchQueue.main.async {
            delegate.clearProperties()
        }
    }

    // MARK: - API requests

    /// Creates a conversation on the Apptentive server using the API.
    private func postConversation(_ conversation: Conversation, with credentials: PendingAPICredentials, token: String? = nil) async throws -> ConversationResponse {
        Logger.default.info("Creating a new conversation via Apptentive API.")

        let identifier = token == nil ? "create conversation" : "log in new conversation"
        return try await self.requestRetrier.start(ApptentiveAPI.createConversation(conversation, with: credentials, token: token), identifier: identifier)
    }

    /// Creates a conversation on the Apptentive server using the API.
    private func resumeSession(with credentials: AnonymousAPICredentials) async throws -> SessionResponse {
        Logger.default.info("Creating a new session via Apptentive API.")

        let sessionCredentials = AuthenticatedAPICredentials(appCredentials: credentials.appCredentials, conversationCredentials: credentials.conversationCredentials)
        return try await self.requestRetrier.start(ApptentiveAPI.resumeSession(with: sessionCredentials), identifier: "resume session")
    }

    /// Retrieves a message list from the Apptentive API.
    internal func getMessagesIfNeeded(with credentials: AnonymousAPICredentials) {
        Task {
            let messagesNeedDownloading = await messageManager.messagesNeedDownloading
            if await !self.requestRetrier.requestIsUnderway(for: "get messages") && messagesNeedDownloading {
                do {
                    let messagesResponse: MessagesResponse = try await self.requestRetrier.start(
                        ApptentiveAPI.getMessages(with: credentials, afterMessageWithID: self.messageManager.lastDownloadedMessageID, pageSize: self.dataProvider.isDebugBuild ? "5" : nil), identifier: "get messages")
                    Logger.default.debug("Message List received.")

                    let didReceiveNewMessages = await self.messageManager.update(with: messagesResponse)
                    self.messageFetchCompletion?(didReceiveNewMessages ? .newData : .noData)

                } catch let error {
                    Logger.network.error("Failed to download message list: \(error)")
                    self.messageFetchCompletion?(.failed)
                }

                self.messageFetchCompletion = nil
            }
        }
    }

    /// Retrieves an engagement manifest from the Apptentive API if the current one is missing or expired.
    private func getInteractionsIfNeeded(with credentials: AnonymousAPICredentials) {
        // Check that the engagement manifest in memory (if any) is expired.
        Task {
            if await !self.requestRetrier.requestIsUnderway(for: "get interactions") && (self.targeter.engagementManifest.expiry ?? Date.distantPast) < Date() {
                Logger.default.info("Requesting new engagement manifest via Apptentive API (current one is absent or stale).")

                do {
                    let engagementManifest: EngagementManifest = try await self.requestRetrier.start(ApptentiveAPI.getInteractions(with: credentials), identifier: "get interactions")
                    Logger.default.debug("New engagement manifest received.")

                    self.targeter.engagementManifest = engagementManifest
                    await self.delegate?.prefetchResources(at: engagementManifest.prefetch ?? [])
                } catch let error {
                    Logger.network.error("Failed to download engagement manifest: \(error).")
                }
            }
        }
    }

    /// Retrieves a Configuration object from the Apptentive API if the current one is missing or expired.
    private func getConfigurationIfNeeded(with credentials: AnonymousAPICredentials) {
        // Check that the configuration in memory (if any) is expired.
        Task {
            if await !self.requestRetrier.requestIsUnderway(for: "get configuration") && (self.configuration?.expiry ?? Date.distantPast) < Date() {
                Logger.default.info("Requesting new app configuration via Apptentive API (current one is absent or stale).")

                do {
                    let configuration: Configuration = try await self.requestRetrier.start(ApptentiveAPI.getConfiguration(with: credentials), identifier: "get configuration")
                    Logger.default.debug("New app configuration received.")

                    self.configuration = configuration

                } catch let error {
                    Logger.network.error("Failed to download app configuration: \(error).")
                }
            }
        }
    }

    static let urlSessionConfiguration: URLSessionConfiguration = {
        let configuration = URLSessionConfiguration.default

        #if DEBUG
            configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        #endif

        configuration.timeoutIntervalForRequest = 60  // Default is 60
        configuration.timeoutIntervalForResource = 600  // Default is 7 days (!)
        configuration.waitsForConnectivity = true

        return configuration
    }()
}
