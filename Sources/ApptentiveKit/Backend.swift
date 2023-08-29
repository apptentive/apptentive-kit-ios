//
//  Backend.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Describes an object that can provide an environment and an interaction presenter.
protocol BackendDelegate: AnyObject {
    var environment: GlobalEnvironment { get }
    var interactionPresenter: InteractionPresenter { get }

    func authenticationDidFail(with error: Swift.Error)
}

/// The backend includes internal top-level methods used by the SDK.
///
/// It is implemented as a separate class from `Apptentive` to help enforce the main queue/background queue separation.
class Backend: PayloadAuthenticationDelegate {

    /// The private background queue used for executing methods in this class.
    let queue: DispatchQueue

    /// The `Apptentive` instance that owns this `Backend` instance.
    weak var delegate: BackendDelegate?

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
    var conversation: Conversation? {
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

    /// A completion handler that is called when a message fetch completes.
    var messageFetchCompletionHandler: ((UIBackgroundFetchResult) -> Void)? {
        didSet {
            if let anonymousCredentials = self.state.anonymousCredentials, self.messageFetchCompletionHandler != nil {
                self.messageManager.forceMessageDownload = true

                self.getMessagesIfNeeded(with: anonymousCredentials)
            }
        }
    }

    /// The name of the Application Support subdirectory where Apptentive files are stored.
    let containerName: String

    /// Initializes a new backend instance.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - environment: The environment object used to initialize the conversation.
    ///   - baseURL: The URL where the Apptentive API is based.
    ///   - containerName: The name of the container directory in Application Support and Caches.
    convenience init(queue: DispatchQueue, environment: GlobalEnvironment, baseURL: URL, containerName: String) {
        let conversation = Conversation(environment: environment)
        let targeter = Targeter(engagementManifest: EngagementManifest.placeholder)
        let messageManager = MessageManager(notificationCenter: NotificationCenter.default)
        let client = HTTPClient(requestor: URLSession(configuration: Self.urlSessionConfiguration), baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: environment.sdkVersion), languageCode: environment.preferredLocalization)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: HTTPRetryPolicy(), client: client, queue: queue)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let roster = ConversationRoster(active: .init(state: .placeholder, path: "placeholder"), loggedOut: [])
        let state = BackendState(isInForeground: false, isProtectedDataAvailable: false, roster: roster, fatalError: false)

        self.init(
            queue: queue, conversation: conversation, state: state, containerName: containerName, targeter: targeter, messageManager: messageManager, requestRetrier: requestRetrier, payloadSender: payloadSender, isDebugBuild: environment.isDebugBuild)
    }

    /// This initializer intended for testing only.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - conversation: The conversation that the backend should start with.
    ///   - state: The initial state of the backend object.
    ///   - containerName: The name of the container directory in Application Support and Caches.
    ///   - targeter: The targeter to use to determine if events should show an interaction.
    ///   - messageManager: The message manager to use to manage messages for Message Center.
    ///   - requestRetrier: The Apptentive API request retrier to use to send API requests.
    ///   - payloadSender: The payload sender to use to send updates to the API.
    ///   - isDebugBuild: Indicates if in debug mode received from the ConversationEnvironment.
    init(queue: DispatchQueue, conversation: Conversation, state: BackendState, containerName: String, targeter: Targeter, messageManager: MessageManager, requestRetrier: HTTPRequestRetrier, payloadSender: PayloadSending, isDebugBuild: Bool) {
        self.queue = queue
        self.conversation = conversation
        self.state = state
        self.containerName = containerName
        self.targeter = targeter
        self.messageManager = messageManager
        self.requestRetrier = requestRetrier
        self.payloadSender = payloadSender
        self.isDebugBuild = isDebugBuild
        self.jsonEncoder = JSONEncoder.apptentive

        self.payloadSender.authenticationDelegate = self
        self.jsonEncoder.dateEncodingStrategy = .secondsSince1970
    }

    deinit {
        self.housekeepingTimer?.setEventHandler(handler: nil)
        self.housekeepingTimer?.cancel()
        self.housekeepingTimer?.resume()
    }

    /// Connects the backend to the Apptentive API.
    /// - Parameters:
    ///   - appCredentials: The App Key and App Signature to use when communicating with the Apptentive API
    ///   - environment: An object implementing the `GlobalEnvironment` protocol.
    ///   - completion: A completion handler to be called when conversation credentials are loaded/retrieved, or when loading/retrieving fails.
    func register(appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment, completion: @escaping (Result<ConnectionType, Error>) -> Void) {
        self.registerCompletion = completion
        self.state.appCredentials = appCredentials
    }

    /// Sets up access to persistent storage and loads any previously-saved conversation data if needed.
    ///
    /// This method may be called multiple times if the device is locked with the app in the foreground and then unlocked.
    /// - Parameter environment: An object implementing the `GlobalEnvironment` protocol.
    /// - Throws: An error if the conversation file exists but can't be read, or if the saved conversation can't be merged with the in-memory conversation.
    func protectedDataDidBecomeAvailable(environment: GlobalEnvironment) throws {
        self.state.isProtectedDataAvailable = true
    }

    /// Reliquishes access to persistent storage.
    ///
    /// Called when the device is locked with the app in the foreground.
    func protectedDataWillBecomeUnavailable() {
        self.state.isProtectedDataAvailable = false
    }

    func willEnterForeground(environment: GlobalEnvironment) {
        self.state.isInForeground = true
    }

    func didEnterBackground(environment: GlobalEnvironment) {
        self.state.isInForeground = false
    }

    func invalidateEngagementManifestForDebug() {
        if self.isDebugBuild {
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

    func authenticationDidFail(with response: ErrorResponse?) {
        DispatchQueue.main.async {
            self.delegate?.authenticationDidFail(with: ApptentiveError.authenticationFailed(reason: response?.errorType, responseString: response?.error))
        }
    }

    // MARK: - Methods called from Apptentive+InteractionDelegate on backend queue

    /// Engages an event.
    ///
    /// This consists of the following steps:
    /// 1. Sends an API request to create the event on the server.
    /// 2. Increments the relevant engagement metric in the conversation.
    /// 3. Presents an interaction if one was triggered by the event being engaged.
    /// - Parameters:
    ///   - event: The `Event` object to be engaged.
    ///   - completion: A completion handler whose argument indicates whether engaging the event resulted in the presentation of an interaction.
    func engage(event: Event, completion: ((Result<Bool, Error>) -> Void)?) {
        ApptentiveLogger.engagement.info("Engaged event “\(event.codePointName)”")

        if self.conversation == nil {
            ApptentiveLogger.engagement.info("No active conversation (logged out).")
        }

        do {
            try self.payloadSender.send(Payload(wrapping: event, with: self.payloadContext), persistEagerly: false)
        } catch let error {
            ApptentiveLogger.default.error("Unable to enqueue event payload: \(error).")
        }

        self.conversation?.codePoints.invoke(for: event.codePointName)

        do {
            if let conversation = self.conversation, let interaction = try self.targeter.interactionData(for: event, state: conversation) {
                try self.presentInteraction(interaction, completion: completion)
            } else {
                completion?(.success(false))
            }
        } catch let error {
            completion?(.failure(error))
        }
    }

    /// Sends a survey response to the Apptentive API.
    /// - Parameter surveyResponse: The survey response to send to the API.
    func send(surveyResponse: SurveyResponse) {
        do {
            try self.payloadSender.send(Payload(wrapping: surveyResponse, with: self.payloadContext), persistEagerly: true)
        } catch let error {
            ApptentiveLogger.default.error("Unable to enqueue survey response payload: \(error).")
        }
    }

    /// Evaluates a list of invocations and presents an interaction, if needed.
    /// - Parameters:
    ///   - invocations: The invocations to evaluate.
    ///   - completion: A completion handler called with the ID of the presented interaction, if any.
    func invoke(_ invocations: [EngagementManifest.Invocation], completion: @escaping (String?) -> Void) {
        do {
            guard let conversation = self.conversation else {
                throw ApptentiveError.noActiveConversation
            }

            guard let destinationInteraction = try self.targeter.interactionData(for: invocations, state: conversation) else {
                throw ApptentiveError.internalInconsistency
            }

            try self.presentInteraction(destinationInteraction) { (result) in
                switch result {
                case .success(true):
                    completion(destinationInteraction.id)
                case .success(false):
                    ApptentiveLogger.default.error("TextModal button had no invocations with matching criteria.")
                    apptentiveCriticalError("TextModal button had no invocations with matching criteria.")
                case .failure(let error):
                    ApptentiveLogger.default.error("Failure presenting interaction based on invocations: \(error).")
                }
            }
        } catch let error {
            completion(nil)

            ApptentiveLogger.interaction.error("TextModal button targeting error: \(error).")
            apptentiveCriticalError("TextModal button targeting error: \(error).")
        }
    }

    /// Gets the identifier for the next page, if any, by evaluating the specified advance logic.
    /// - Parameters:
    ///   - advanceLogic: The advance logic to evaluate.
    ///   - completion: A completion handler called with the result of the evaluation.
    func getNextPageID(for advanceLogic: [AdvanceLogic], completion: @escaping (Result<String?, Error>) -> Void) {
        completion(
            Result(catching: {
                guard let conversation = self.conversation else {
                    throw ApptentiveError.noActiveConversation
                }

                for item in advanceLogic {
                    if try item.criteria.isSatisfied(for: conversation) {
                        return item.pageID
                    }
                }

                return nil
            })
        )
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
    func sendMessage(_ message: MessageList.Message, with customData: CustomData? = nil) throws {
        guard let attachmentManager = self.messageManager.attachmentManager else {
            throw ApptentiveError.internalInconsistency
        }

        let payload = try Payload(wrapping: message, with: self.payloadContext, customData: customData, attachmentURLProvider: attachmentManager)

        self.payloadSender.send(payload, persistEagerly: true)

        self.messageManager.addQueuedMessage(message, with: payload.identifier)
    }

    /// Checks if the event can trigger an interaction.
    /// - Parameters:
    ///  - event: The event used to check if it can trigger an interaction.
    ///  - completion: A completion handler that is called with a boolean indicating whether or not an interaction can be shown using the event.
    func canShowInteraction(event: Event, completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            guard let conversation = self.conversation else {
                throw ApptentiveError.noActiveConversation
            }

            let result = try self.targeter.interactionData(for: event, state: conversation)
            completion(.success(result != nil))
        } catch let error {
            completion(.failure(error))
        }
    }

    func logIn(with token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            guard let jwtSubject = try JWT(string: token).payload.subject else {
                throw ApptentiveError.missingSubClaim
            }

            guard let appCredentials = self.state.appCredentials else {
                throw ApptentiveError.loginCalledBeforeRegister
            }

            guard let environment = self.delegate?.environment else {
                throw ApptentiveError.internalInconsistency
            }

            let activeConversationState = self.state.roster.active?.state
            let loggedOutConversationID = self.state.roster.loggedOutRecord(with: jwtSubject)?.id

            switch (activeConversationState, loggedOutConversationID) {
            case (.none, .some(let id)):
                ApptentiveLogger.default.debug("Logging in logged-out conversation with subject \(jwtSubject) and id \(id).")

                self.resumeSession(with: AnonymousAPICredentials(appCredentials: appCredentials, conversationCredentials: .init(id: id, token: token))) { result in
                    switch result {
                    case .success(let sessionResponse):
                        completion(
                            Result {
                                try self.state.roster.logInLoggedOutRecord(with: jwtSubject, token: token, encryptionKey: sessionResponse.encryptionKey)
                                try self.saveRoster()
                            })

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case (.none, .none):
                ApptentiveLogger.default.debug("Logging in new conversation with subject \(jwtSubject).")

                let conversation = Conversation(environment: environment)
                self.postConversation(conversation, with: PendingAPICredentials(appCredentials: appCredentials), token: token) { result in
                    switch result {
                    case .success(let conversationResponse):
                        self.lastSyncedConversation = conversation
                        completion(
                            Result {
                                try self.state.roster.createLoggedInRecord(with: jwtSubject, id: conversationResponse.id, token: token, encryptionKey: conversationResponse.encryptionKey)
                                try self.saveRoster()
                            })

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

            case (.anonymous(credentials: let conversationCredentials), .none):
                ApptentiveLogger.default.debug("Authenticating anonymous conversation with identifier \(conversationCredentials.id) using subject \(jwtSubject).")

                self.resumeSession(with: AnonymousAPICredentials(appCredentials: appCredentials, conversationCredentials: .init(id: conversationCredentials.id, token: token))) { result in
                    switch result {
                    case .success(let sessionResponse):
                        completion(
                            Result {
                                try self.state.roster.logInAnonymousRecord(with: jwtSubject, token: token, encryptionKey: sessionResponse.encryptionKey)
                                try self.saveRoster()
                            })

                    case .failure(let error):
                        completion(.failure(error))
                    }
                }

                break

            case (.anonymousPending, _), (.placeholder, _):
                completion(.failure(ApptentiveError.activeConversationPending))

            case (.loggedIn(credentials: let credentials, subject: let subject, encryptionKey: _), _):
                completion(.failure(ApptentiveError.alreadyLoggedIn(subject: subject, id: credentials.id)))

            default:
                completion(.failure(ApptentiveError.internalInconsistency))
            }
        } catch let error {
            completion(.failure(error))
        }
    }

    func logOut() throws {
        self.requestRetrier.cancel(identifier: "log in new conversation")
        self.requestRetrier.cancel(identifier: "resume session")

        if case .loggedIn(credentials: let credentials, subject: let subject, encryptionKey: _) = self.state.roster.active?.state {
            ApptentiveLogger.default.debug("Logging out conversation with subject \(subject) and id \(credentials.id).")

            self.engage(event: .logout, completion: nil)

            try self.payloadSender.send(.logout(with: self.payloadContext), persistEagerly: true)
            try self.state.roster.logOutActiveConversation()
            try self.saveRoster()
        } else {
            throw ApptentiveError.notLoggedIn
        }
    }

    func updateToken(_ token: String, completion: (Result<Void, Error>) -> Void) {
        do {
            guard let jwtSubject = try JWT(string: token).payload.subject else {
                throw ApptentiveError.missingSubClaim
            }

            ApptentiveLogger.default.debug("Updating JWT for logged-in conversation with subject \(jwtSubject).")
            try self.state.roster.updateLoggedInRecord(with: token, matching: jwtSubject)
            try self.saveRoster()

            completion(.success(()))
        } catch let error {
            completion(.failure(error))
        }
    }

    private func startAnonymousConversation(with credentials: PendingAPICredentials) throws {
        guard let conversation = self.conversation else {
            throw ApptentiveError.internalInconsistency
        }

        ApptentiveLogger.default.debug("Registering new anonymous conversation.")
        let postedConversation = conversation
        self.postConversation(conversation, with: credentials) { result in
            switch result {
            case .success(let conversationResponse):
                self.lastSyncedConversation = postedConversation
                let result: Result<ConnectionType, Error> = Result {
                    try self.state.roster.registerAnonymousRecord(with: conversationResponse.id, token: conversationResponse.token)
                    try self.saveRoster()
                    return ConnectionType.new
                }
                self.registerCompletion?(result)
                self.registerCompletion = nil

            case .failure(let error):
                self.registerCompletion?(.failure(error))
                self.registerCompletion = nil

                self.state.fatalError = true
            }
        }
    }

    var state: BackendState {
        didSet {
            if self.state.summary != oldValue.summary {
                self.handleTransition((from: oldValue.summary, to: self.state.summary))
            }
        }
    }

    // MARK: - Private

    private var sessionID: String?

    private let jsonEncoder: JSONEncoder

    private let requestRetrier: HTTPRequestRetrier

    private let payloadSender: PayloadSending

    private let isDebugBuild: Bool

    private var configuration: Configuration? {
        didSet {
            if let configuration = self.configuration {
                self.messageManager.foregroundPollingInterval = configuration.messageCenter.foregroundPollingInterval
                self.messageManager.backgroundPollingInterval = configuration.messageCenter.backgroundPollingInterval
            }
        }
    }

    /// The saver used to save the conversation roster to persistent storage.
    private var rosterSaver: PropertyListSaver<ConversationRoster>?

    /// The saver used to save the conversation to persistent storage.
    private var conversationSaver: EncryptedPropertyListSaver<Conversation>?

    /// Whether the conversation has changes that need to be saved to persistent storage.
    private var conversationNeedsSaving: Bool = false

    /// A timer that periodically runs a task to save the conversation and payload sender.
    private var housekeepingTimer: DispatchSourceTimer?

    /// A flag indicating whether the housekeeping timer is active.
    private var housekeepingTimerIsActive = false

    /// The version of the conversation that was last sent to the API.
    private var lastSyncedConversation: Conversation?

    private var registerCompletion: ((Result<ConnectionType, Error>) -> Void)?

    private func handleTransition(_ transition: (from: BackendState.Summary, to: BackendState.Summary)) {
        ApptentiveLogger.default.debug("Backend state transition \(String(describing: transition))")

        do {
            guard let environment = self.delegate?.environment else {
                throw ApptentiveError.internalInconsistency
            }

            let containerURL = try Self.containerDirectoryURL(with: containerName, environment: environment)
            let cacheURL = try Self.cacheDirectoryURL(with: containerName, environment: environment)

            switch transition {
            case (from: .waiting, to: .loading(let appCredentials)), (from: .backgrounded, to: .loading(let appCredentials)):
                try self.createCommonSavers(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, environment: environment)
                self.loadCommonFiles(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, environment: environment)

                if let activeRecord = self.state.roster.active {
                    try createRecordSavers(for: activeRecord, containerURL: containerURL, environment: environment)
                    self.loadRecordFiles(for: activeRecord, containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, environment: environment)
                }

            case (from: .loading, to: .posting(let pendingCredentials)):
                try self.startAnonymousConversation(with: pendingCredentials)

            case (from: .posting, to: .anonymous(let payloadCredentials)):
                self.startSession()

                self.registerCompletion?(.success(.new))
                self.registerCompletion = nil

                try self.payloadSender.updateCredentials(payloadCredentials, for: "placeholder", encryptionContext: nil)
                self.startHousekeepingTimer()

            case (from: .loading, to: .anonymous(let payloadCredentials)):
                self.startSession()

                self.registerCompletion?(.success(.cached))
                self.registerCompletion = nil

                try self.payloadSender.updateCredentials(payloadCredentials, for: "placeholder", encryptionContext: nil)
                self.startHousekeepingTimer()

            case (from: .loading, to: .loggedIn(let payloadCredentials, let encryptionContext)):
                self.registerCompletion?(.success(.cached))
                self.registerCompletion = nil
                self.startSession()

                try self.payloadSender.updateCredentials(payloadCredentials, for: "placeholder", encryptionContext: encryptionContext)
                self.startHousekeepingTimer()

            case (from: .loading, to: .loggedOut):
                self.conversation = nil
                self.registerCompletion?(.success(.cached))
                self.registerCompletion = nil

            case (from: .anonymous, to: .loggedIn(let payloadCredentials, let encryptionContext)):
                guard let activeRecord = self.state.roster.active else {
                    throw ApptentiveError.internalInconsistency
                }

                try self.createRecordSavers(for: activeRecord, containerURL: containerURL, environment: environment)
                try self.saveConversation()
                try self.messageManager.saveMessages()
                try self.removePlaintextFiles(in: containerURL, for: activeRecord, environment: environment)
                try self.payloadSender.updateCredentials(payloadCredentials, for: activeRecord.path, encryptionContext: encryptionContext)

                self.engage(event: .login, completion: nil)

            case (from: .loggedOut, to: .loggedIn):
                guard let activeRecord = self.state.roster.active, let appCredentials = self.state.appCredentials else {
                    throw ApptentiveError.internalInconsistency
                }

                try self.createRecordSavers(for: activeRecord, containerURL: containerURL, environment: environment)
                self.loadRecordFiles(for: activeRecord, containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, environment: environment)
                self.resumeHousekeepingTimer()

                self.startSession()
                self.engage(event: .login, completion: nil)

            case (from: .loggedIn, to: .loggedOut):
                self.suspendHousekeepingTimer()
                self.conversation = nil
                try self.messageManager.deleteCachedMessages()

            case (from: .loggedIn, to: .loggedIn(let payloadCredentials, let encryptionContext)):  // Conversation credentials were updated.
                guard let activeRecord = self.state.roster.active else {
                    throw ApptentiveError.internalInconsistency
                }

                try self.payloadSender.updateCredentials(payloadCredentials, for: activeRecord.path, encryptionContext: encryptionContext)

            case (from: .backgrounded, to: .anonymous), (from: .backgrounded, to: .loggedIn):
                self.startSession()
                self.payloadSender.resume()
                self.resumeHousekeepingTimer()

            case (from: .anonymous, to: .backgrounded), (from: .loggedIn, to: .backgrounded):
                environment.startBackgroundTask()
                self.endSession()

                self.syncConversationWithAPI()

                self.payloadSender.drain {
                    DispatchQueue.main.async {
                        environment.endBackgroundTask()
                    }
                }

                self.suspendHousekeepingTimer()
                self.saveToPersistentStorageIfNeeded()

            case (from: _, to: .backgrounded):
                break  // Allowed state transition, no action.

            case (from: .backgrounded, to: _):
                break  // Allowed state transition, no action.

            case (from: .locked, to: _):
                if let appCredentials = self.state.appCredentials, state.isProtectedDataAvailable {
                    try self.createCommonSavers(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, environment: environment)

                    if let activeRecord = self.state.roster.active {
                        try self.createRecordSavers(for: activeRecord, containerURL: containerURL, environment: environment)
                    }
                }

            case (from: _, to: .locked):
                self.suspendHousekeepingTimer()
                self.destroySavers()

            default:
                throw ApptentiveError.unsupportedBackendStateTransition
            }
        } catch let error {
            apptentiveCriticalError("Error during state transition (from \(transition.from) to \(transition.to): \(error). Suspending SDK operation until next cold launch.")
            self.state.fatalError = true
        }
    }

    private func startSession() {
        self.sessionID = UUID().uuidString
        self.engage(event: .launch(), completion: nil)
        self.invalidateEngagementManifestForDebug()
        self.messageManager.forceMessageDownload = true
        self.requestRetrier.retryPolicy.resetRetryDelay()
    }

    private func endSession() {
        self.engage(event: .exit(), completion: nil)
        self.sessionID = nil
    }

    private func createCommonSavers(containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment) throws {
        self.rosterSaver = PropertyListSaver<ConversationRoster>(containerURL: containerURL, filename: CurrentLoader.rosterFilename(for: appCredentials), fileManager: environment.fileManager)
        self.payloadSender.saver = PayloadSender.createSaver(containerURL: containerURL, filename: CurrentLoader.payloadsFilename(for: appCredentials), fileManager: environment.fileManager)
        self.messageManager.attachmentManager = AttachmentManager(fileManager: environment.fileManager, requestor: URLSession.shared, cacheContainerURL: cacheURL, savedContainerURL: containerURL)
    }

    private func loadCommonFiles(containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment) {
        CurrentLoader.loadLatestVersion(containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, environment: environment) { loader in
            let roster = try loader.loadRoster()
            try self.payloadSender.load(from: loader)

            self.state.roster = roster

            // Save any data that might have been migrated
            try self.saveRoster()
            try self.payloadSender.savePayloadsIfNeeded()
        }
    }

    private func createRecordSavers(for record: ConversationRoster.Record, containerURL: URL, environment: GlobalEnvironment) throws {
        let recordContainerURL = containerURL.appendingPathComponent(record.path)
        self.conversationSaver = EncryptedPropertyListSaver<Conversation>(containerURL: recordContainerURL, filename: CurrentLoader.conversationFilename, fileManager: environment.fileManager, encryptionKey: record.encryptionKey)
        self.messageManager.saver = MessageManager.createSaver(containerURL: recordContainerURL, filename: CurrentLoader.messagesFilename, fileManager: environment.fileManager, encryptionKey: record.encryptionKey)
    }

    private func loadRecordFiles(for activeRecord: ConversationRoster.Record, containerURL: URL, cacheURL: URL, appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment) {
        CurrentLoader.loadLatestVersion(for: activeRecord, containerURL: containerURL, cacheURL: cacheURL, appCredentials: appCredentials, environment: environment) { loader in
            try self.loadConversation(from: loader, for: activeRecord)
            try self.messageManager.load(from: loader, for: activeRecord)

            try self.saveConversationIfNeeded()
            try self.messageManager.saveMessagesIfNeeded()
        }
    }

    private func removePlaintextFiles(in containerURL: URL, for activeRecord: ConversationRoster.Record, environment: GlobalEnvironment) throws {
        let plaintextConversationFileURL = containerURL.appendingPathComponent(CurrentLoader.conversationFilePath(for: activeRecord))
        if environment.fileManager.fileExists(atPath: plaintextConversationFileURL.path) {
            try environment.fileManager.removeItem(at: plaintextConversationFileURL)
        }

        let plaintextMessageListFileURL = containerURL.appendingPathComponent(CurrentLoader.messagesFilePath(for: activeRecord))
        if environment.fileManager.fileExists(atPath: plaintextMessageListFileURL.path) {
            try environment.fileManager.removeItem(at: plaintextMessageListFileURL)
        }
    }

    private func destroySavers() {
        self.messageManager.attachmentManager = nil
        self.messageManager.saver = nil
        self.payloadSender.saver = nil
        self.conversationSaver = nil
        self.rosterSaver = nil
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

    private func presentInteraction(_ interaction: Interaction, completion: ((Result<Bool, Error>) -> Void)?) throws {
        guard let delegate = self.delegate else {
            throw ApptentiveError.internalInconsistency
        }

        DispatchQueue.main.async {
            do {
                try delegate.interactionPresenter.presentInteraction(interaction)

                completion?(.success(true))

                self.queue.async {
                    self.conversation?.interactions.invoke(for: interaction.id)
                }
            } catch let error {
                completion?(.failure(error))
                ApptentiveLogger.default.error("Interaction presentation error: \(error)")
                apptentiveCriticalError("Interaction presentation error: \(error)")
            }
        }
    }

    // MARK: API syncing

    /// If registered, sends updates to person, device, and app release if they have changed since the last sync.
    ///
    /// Would be private but needs to be internal for testing.
    internal func syncConversationWithAPI() {
        guard let conversation = self.conversation else {
            ApptentiveLogger.network.debug("Skipping API sync: No active conversation.")
            return
        }

        guard let credentials = self.state.anonymousCredentials else {
            ApptentiveLogger.network.debug("Skipping API sync: Not yet registered.")
            return
        }

        guard let lastSyncedConversation = self.lastSyncedConversation else {
            ApptentiveLogger.network.debug("Skipping API sync: No previously synced conversation.")
            return
        }

        self.getInteractionsIfNeeded(with: credentials)

        self.getConfigurationIfNeeded(with: credentials)

        self.getMessagesIfNeeded(with: credentials)

        if AppReleaseContent(with: lastSyncedConversation.appRelease) != AppReleaseContent(with: conversation.appRelease) {
            ApptentiveLogger.network.debug("App release data changed. Enqueueing update.")
            do {
                try self.payloadSender.send(Payload(wrapping: conversation.appRelease, with: self.payloadContext), persistEagerly: false)
                self.lastSyncedConversation?.appRelease = conversation.appRelease
            } catch let error {
                ApptentiveLogger.default.error("Unable to enqueue app release payload: \(error).")
            }
        }

        if PersonContent(with: lastSyncedConversation.person) != PersonContent(with: conversation.person) {
            ApptentiveLogger.network.debug("Person data changed. Enqueueing update.")
            do {
                try self.payloadSender.send(Payload(wrapping: conversation.person, with: self.payloadContext), persistEagerly: false)
                self.lastSyncedConversation?.person = conversation.person
            } catch let error {
                ApptentiveLogger.default.error("Unable to enqueue person payload: \(error).")
            }
        }

        if DeviceContent(with: lastSyncedConversation.device) != DeviceContent(with: conversation.device) {
            ApptentiveLogger.network.debug("Device data changed. Enqueueing update.")
            do {
                try self.payloadSender.send(Payload(wrapping: conversation.device, with: self.payloadContext), persistEagerly: false)

                if lastSyncedConversation.device.localeRaw != conversation.device.localeRaw {
                    ApptentiveLogger.engagement.debug("Locale changed. Invalidating engagement manifest.")
                    self.invalidateEngagementManifest()
                }

                self.lastSyncedConversation?.device = conversation.device
            } catch let error {
                ApptentiveLogger.default.error("Unable to enqueue device payload: \(error).")
            }
        }
    }

    // MARK: Persistence

    /// Saves the conversation and payload queue to persistent storage if needed.
    ///
    /// Would be private but needs to be internal for testing.
    internal func saveToPersistentStorageIfNeeded() {
        do {
            try self.saveConversationIfNeeded()
            try self.payloadSender.savePayloadsIfNeeded()
            try self.messageManager.saveMessagesIfNeeded()
        } catch let error {
            ApptentiveLogger.default.error("Unable to save files to persistent storage: \(error).")
            apptentiveCriticalError("Unable to save files to persistent storage: \(error.localizedDescription)")
        }
    }

    /// Saves the conversation roster to persistent storage.
    ///
    /// Would be private but needs to be internal for testing.
    /// - Throws: An error if the saver is nil.
    internal func saveRoster() throws {
        guard let saver = self.rosterSaver else {
            throw ApptentiveError.internalInconsistency
        }

        try saver.save(self.state.roster)
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

    private func startHousekeepingTimer() {
        let housekeepingTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        housekeepingTimer.schedule(deadline: .now(), repeating: .seconds(10), leeway: .seconds(1))
        housekeepingTimer.setEventHandler { [weak self] in
            ApptentiveLogger.default.debug("Running periodic housekeeping task")
            self?.syncConversationWithAPI()
            self?.saveToPersistentStorageIfNeeded()
        }

        housekeepingTimer.resume()

        self.housekeepingTimer = housekeepingTimer
        self.housekeepingTimerIsActive = true
    }

    private func resumeHousekeepingTimer() {
        if let housekeepingTimer = self.housekeepingTimer {
            if !housekeepingTimerIsActive {
                housekeepingTimer.resume()
                self.housekeepingTimerIsActive = true
            }
        } else {
            self.startHousekeepingTimer()
        }
    }

    private func suspendHousekeepingTimer() {
        if housekeepingTimerIsActive {
            self.housekeepingTimer?.suspend()
            self.housekeepingTimerIsActive = false
        }
    }

    // MARK: - API requests

    /// Creates a conversation on the Apptentive server using the API.
    private func postConversation(_ conversation: Conversation, with credentials: PendingAPICredentials, token: String? = nil, completion: @escaping (Result<ConversationResponse, Error>) -> Void) {
        ApptentiveLogger.default.info("Creating a new conversation via Apptentive API.")

        let identifier = token == nil ? "create conversation" : "log in new conversation"

        self.requestRetrier.startUnlessUnderway(ApptentiveAPI.createConversation(conversation, with: credentials, token: token), identifier: identifier, completion: completion)
    }

    /// Creates a conversation on the Apptentive server using the API.
    private func resumeSession(with credentials: AnonymousAPICredentials, completion: @escaping (Result<SessionResponse, Error>) -> Void) {
        ApptentiveLogger.default.info("Creating a new session via Apptentive API.")

        let sessionCredentials = AuthenticatedAPICredentials(appCredentials: credentials.appCredentials, conversationCredentials: credentials.conversationCredentials)
        self.requestRetrier.startUnlessUnderway(ApptentiveAPI.resumeSession(with: sessionCredentials), identifier: "resume session", completion: completion)
    }

    /// Retrieves a message list from the Apptentive API.
    internal func getMessagesIfNeeded(with credentials: AnonymousAPICredentials) {
        if self.messageManager.messagesNeedDownloading {
            self.requestRetrier.startUnlessUnderway(ApptentiveAPI.getMessages(with: credentials, afterMessageWithID: self.messageManager.lastDownloadedMessageID, pageSize: self.isDebugBuild ? "5" : nil), identifier: "get messages") {
                (result: Result<MessagesResponse, Error>) in
                switch result {
                case .success(let messagesResponse):
                    ApptentiveLogger.default.debug("Message List received.")

                    let didReceiveNewMessages = self.messageManager.update(with: messagesResponse)
                    self.messageFetchCompletionHandler?(didReceiveNewMessages ? .newData : .noData)

                case .failure(let error):
                    ApptentiveLogger.network.error("Failed to download message list: \(error)")
                    self.messageFetchCompletionHandler?(.failed)
                }

                self.messageFetchCompletionHandler = nil
            }
        }
    }

    /// Retrieves an engagement manifest from the Apptentive API if the current one is missing or expired.
    private func getInteractionsIfNeeded(with credentials: AnonymousAPICredentials) {
        // Check that the engagement manifest in memory (if any) is expired.
        if (self.targeter.engagementManifest.expiry ?? Date.distantPast) < Date() {
            ApptentiveLogger.default.info("Requesting new engagement manifest via Apptentive API (current one is absent or stale).")

            self.requestRetrier.startUnlessUnderway(ApptentiveAPI.getInteractions(with: credentials), identifier: "get interactions") { (result: Result<EngagementManifest, Error>) in
                switch result {
                case .success(let engagementManifest):
                    ApptentiveLogger.default.debug("New engagement manifest received.")

                    self.targeter.engagementManifest = engagementManifest

                case .failure(let error):
                    ApptentiveLogger.network.error("Failed to download engagement manifest: \(error).")
                }
            }
        }
    }

    /// Retrieves a Configuration object from the Apptentive API if the current one is missing or expired.
    private func getConfigurationIfNeeded(with credentials: AnonymousAPICredentials) {
        // Check that the configuration in memory (if any) is expired.
        if (self.configuration?.expiry ?? Date.distantPast) < Date() {
            ApptentiveLogger.default.info("Requesting new app configuration via Apptentive API (current one is absent or stale).")

            self.requestRetrier.startUnlessUnderway(ApptentiveAPI.getConfiguration(with: credentials), identifier: "get configuration") { (result: Result<Configuration, Error>) in
                switch result {
                case .success(let configuration):
                    ApptentiveLogger.default.debug("New app configuration received.")

                    self.configuration = configuration

                case .failure(let error):
                    ApptentiveLogger.network.error("Failed to download app configuration: \(error).")
                }
            }
        }
    }

    private static func containerDirectoryURL(with containerName: String, environment: GlobalEnvironment) throws -> URL {
        return try environment.applicationSupportURL().appendingPathComponent(containerName)
    }

    private static func cacheDirectoryURL(with containerName: String, environment: GlobalEnvironment) throws -> URL {
        return try environment.cachesURL().appendingPathComponent(containerName)
    }

    private static let urlSessionConfiguration: URLSessionConfiguration = {
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
