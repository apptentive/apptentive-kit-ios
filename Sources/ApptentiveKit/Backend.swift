//
//  Backend.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

/// The backend includes internal top-level methods used by the SDK.
///
/// It is implemented as a separate class from `Apptentive` to help enforce the main queue/background queue separation.
class Backend {
    /// The private background queue used for executing methods in this class.
    let queue: DispatchQueue

    /// The `Apptentive` instance that owns this `Backend` instance.
    weak var frontend: Apptentive?

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
    var conversation: Conversation {
        didSet {
            if self.conversation != oldValue {
                self.conversationNeedsSaving = true
            }
        }
    }

    /// The object that determines whether an interaction should be presented when an event is engaged.
    let targeter: Targeter

    /// A Message Manager object which is initialized on launch.
    let messageManager: MessageManager

    private let requestRetrier: HTTPRequestRetrier

    private let payloadSender: PayloadSender

    var messageFetchCompletionHandler: ((UIBackgroundFetchResult) -> Void)? {
        didSet {
            if self.messageFetchCompletionHandler != nil {
                self.messageManager.forceMessageDownload = true

                self.getMessagesIfNeeded()
            }
        }
    }

    private var configuration: Configuration? {
        didSet {
            if let configuration = self.configuration {
                self.messageManager.foregroundPollingInterval = configuration.messageCenter.foregroundPollingInterval
                self.messageManager.backgroundPollingInterval = configuration.messageCenter.backgroundPollingInterval
            }
        }
    }

    /// The name of the Application Support subdirectory where Apptentive files are stored.
    let containerName: String

    /// The saver used to load and save the conversation from/to persistent storage.
    private var conversationSaver: PropertyListSaver<Conversation>?

    /// Whether the conversation has changes that need to be saved to persistent storage.
    private var conversationNeedsSaving: Bool = false

    /// Whether the conversation in memory is a temporary one that should be merged with one loaded from disk.
    private var conversationNeedsLoading: Bool = true

    /// A timer that periodically runs a task to save the conversation and payload sender.
    private var persistenceTimer: DispatchSourceTimer?

    /// A flag indicating whether the persistenc timer is active.
    private var persistenceTimerActive = false

    /// Whether the `register(completion:)` method has been called and the conversation has been created via the API.
    private var isRegistered = false

    private var lastSyncedConversation: Conversation?

    /// Initializes a new backend instance.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - environment: The environment object used to initialize the conversation.
    ///   - baseURL: The URL where the Apptentive API is based.
    ///   - containerName: The name of the container directory in Application Support and Caches.
    convenience init(queue: DispatchQueue, environment: ConversationEnvironment, baseURL: URL, containerName: String) {
        let conversation = Conversation(environment: environment)
        let targeter = Targeter(engagementManifest: EngagementManifest.placeholder)
        let messageManager = MessageManager(notificationCenter: NotificationCenter.default)
        let client = HTTPClient(requestor: URLSession(configuration: Self.urlSessionConfiguration), baseURL: baseURL, userAgent: ApptentiveV9API.userAgent(sdkVersion: environment.sdkVersion))
        let requestRetrier = HTTPRequestRetrier(retryPolicy: HTTPRetryPolicy(), client: client, queue: queue)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)

        self.init(queue: queue, conversation: conversation, containerName: containerName, targeter: targeter, messageManager: messageManager, requestRetrier: requestRetrier, payloadSender: payloadSender)
    }

    /// This initializer intended for testing only.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - conversation: The conversation that the backend should start with.
    ///   - containerName: The name of the container directory in Application Support and Caches.
    ///   - targeter: The targeter to use to determine if events should show an interaction.
    ///   - messageManager: The message manager to use to manage messages for Message Center.
    ///   - requestRetrier: The Apptentive API request retrier to use to send API requests.
    ///   - payloadSender: The payload sender to use to send updates to the API.
    init(queue: DispatchQueue, conversation: Conversation, containerName: String, targeter: Targeter, messageManager: MessageManager, requestRetrier: HTTPRequestRetrier, payloadSender: PayloadSender) {
        self.queue = queue
        self.conversation = conversation
        self.containerName = containerName
        self.targeter = targeter
        self.messageManager = messageManager
        self.requestRetrier = requestRetrier
        self.payloadSender = payloadSender
    }

    deinit {
        self.persistenceTimer?.setEventHandler(handler: nil)
        self.persistenceTimer?.cancel()
        self.persistenceTimer?.resume()
    }

    /// Connects the backend to the Apptentive API.
    /// - Parameters:
    ///   - appCredentials: The App Key and App Signature to use when communicating with the Apptentive API
    ///   - environment: An object implementing the `GlobalEnvironment` protocol.
    ///   - completion: A completion handler to be called when conversation credentials are loaded/retrieved, or when loading/retrieving fails.
    func register(appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment, completion: @escaping (Result<ConnectionType, Error>) -> Void) {
        self.conversation.appCredentials = appCredentials
        self.registerCompletion = completion

        if environment.isProtectedDataAvailable {
            do {
                try self.start(appCredentials: appCredentials, environment: environment)
            } catch let error {
                completion(.failure(error))
                self.registerCompletion = nil
            }
        } else {
            ApptentiveLogger.default.debug("Deferring start until protected data is available.")
        }
    }

    /// Sets up access to persistent storage and loads any previously-saved conversation data if needed.
    ///
    /// This method may be called multiple times if the device is locked with the app in the foreground and then unlocked.
    /// - Parameter environment: An object implementing the `GlobalEnvironment` protocol.
    /// - Throws: An error if the conversation file exists but can't be read, or if the saved conversation can't be merged with the in-memory conversation.
    func protectedDataDidBecomeAvailable(environment: GlobalEnvironment) throws {
        guard let appCredentials = self.conversation.appCredentials else {
            ApptentiveLogger.default.debug("Deferring start until `register` is called.")
            return
        }

        try self.start(appCredentials: appCredentials, environment: environment)
    }

    /// Reliquishes access to persistent storage.
    ///
    /// Called when the device is locked with the app in the foreground.
    func protectedDataWillBecomeUnavailable() {
        self.messageManager.attachmentManager = nil
        self.messageManager.saver = nil
        self.payloadSender.saver = nil
        self.conversationSaver = nil
    }

    func willEnterForeground(environment: GlobalEnvironment) {
        self.invalidateEngagementManifestForDebug(environment: environment)
        Payload.context.startSession()
        self.payloadSender.resume()
        self.resumePersistenceTimer()
        self.messageManager.forceMessageDownload = true
    }

    func didEnterBackground(environment: GlobalEnvironment) {
        environment.startBackgroundTask()

        self.syncConversationWithAPI()

        self.payloadSender.drain {
            DispatchQueue.main.async {
                Payload.context.endSession()
                environment.endBackgroundTask()
            }
        }

        self.suspendPersistenceTimer()
        self.saveToPersistentStorageIfNeeded()
    }

    func invalidateEngagementManifestForDebug(environment: GlobalEnvironment) {
        if environment.isDebugBuild == true {
            self.invalidateEngagementManifest()
        }
    }

    func invalidateEngagementManifest() {
        self.targeter.engagementManifest.expiry = .distantPast
    }

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

        self.payloadSender.send(Payload(wrapping: event))

        self.conversation.codePoints.invoke(for: event.codePointName)

        do {
            if let interaction = try self.targeter.interactionData(for: event, state: self.conversation) {
                try self.presentInteraction(interaction, completion: completion)
            } else {
                DispatchQueue.main.async {
                    completion?(.success(false))
                }
            }
        } catch let error {
            DispatchQueue.main.async {
                completion?(.failure(error))
                ApptentiveLogger.default.error("Targeting error: \(error)")
                apptentiveCriticalError("Targeting error: \(error)")
            }
        }
    }

    /// Sends a survey response to the Apptentive API.
    /// - Parameter surveyResponse: The survey response to send to the API.
    func send(surveyResponse: SurveyResponse) {
        self.payloadSender.send(Payload(wrapping: surveyResponse), persistEagerly: true)
    }

    /// Evaluates a list of invocations and presents an interaction, if needed.
    /// - Parameters:
    ///   - invocations: The invocations to evaluate.
    ///   - completion: A completion handler called with the ID of the presented interaction, if any.
    func invoke(_ invocations: [EngagementManifest.Invocation], completion: @escaping (String?) -> Void) {
        do {
            guard let destinationInteraction = try self.targeter.interactionData(for: invocations, state: self.conversation) else {
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
            DispatchQueue.main.async {
                completion(nil)
            }

            ApptentiveLogger.interaction.error("TextModal button targeting error: \(error).")
            apptentiveCriticalError("TextModal button targeting error: \(error).")
        }
    }

    /// Records a response to an interaction for use later in targeting.
    /// - Parameters:
    ///   - answers: The answers that make up the response.
    ///   - questionID: The identifier associated with the question or note.
    func recordResponse(_ answers: [Answer], for questionID: String) {
        self.conversation.interactions.record(answers, for: questionID)
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

        let payload = Payload(wrapping: message, customData: customData, attachmentURLProvider: attachmentManager)

        self.payloadSender.send(payload, persistEagerly: true)

        self.messageManager.addQueuedMessage(message, with: payload.jsonObject.nonce)
    }

    /// Checks if the event can trigger an interaction.
    /// - Parameters:
    ///  - event: The event used to check if it can trigger an interaction.
    ///  - completion: A completion handler that is called with a boolean indicating whether or not an interaction can be shown using the event.
    func canShowInteraction(event: Event, completion: ((Result<Bool, Error>) -> Void)? = nil) {
        do {
            let result = try self.targeter.interactionData(for: event, state: self.conversation)

            DispatchQueue.main.async {
                completion?(.success(result != nil))
            }
        } catch let error {
            DispatchQueue.main.async {
                completion?(.failure(error))
            }
            ApptentiveLogger.default.error("Error evaluating criteria for event \(event.name). Error: \(error).")
        }
    }

    // MARK: - Private

    private var registerCompletion: ((Result<ConnectionType, Error>) -> Void)?

    private func registerNewConversationIfNeeded(completion: @escaping (Result<ConnectionType, Error>) -> Void) {
        if self.conversation.conversationCredentials != nil {
            self.isRegistered = true

            completion(.success(.cached))
        } else {
            let postedConversation = self.conversation

            self.postConversation { result in
                switch result {
                case .success(let conversationCredentials):
                    self.conversation.conversationCredentials = conversationCredentials
                    self.payloadSender.credentialsProvider = self.conversation
                    self.isRegistered = true

                    self.lastSyncedConversation = postedConversation
                    self.syncConversationWithAPI()

                    do {
                        try self.saveConversationIfNeeded()
                        completion(.success(.new))
                    } catch let error {
                        completion(.failure(error))
                    }

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func start(appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment) throws {
        try self.startFilesAccess(containerName: self.containerName, appCredentials: appCredentials, environment: environment)

        if let completion = self.registerCompletion {
            self.registerNewConversationIfNeeded(completion: completion)

            self.registerCompletion = nil
        }
    }

    private func startFilesAccess(containerName: String, appCredentials: Apptentive.AppCredentials, environment: GlobalEnvironment) throws {
        let containerURL = try Self.containerDirectoryURL(with: containerName, environment: environment)
        let cacheURL = try Self.cacheDirectoryURL(with: containerName, environment: environment)

        try self.createDirectoryIfNeeded(containerURL: containerURL, fileManager: environment.fileManager)
        try self.createDirectoryIfNeeded(containerURL: cacheURL, fileManager: environment.fileManager)

        self.conversationSaver = PropertyListSaver<Conversation>(containerURL: containerURL, filename: CurrentLoader.conversationFilename, fileManager: environment.fileManager)
        self.payloadSender.saver = PayloadSender.createSaver(containerURL: containerURL, filename: CurrentLoader.payloadsFilename, fileManager: environment.fileManager)
        self.messageManager.saver = MessageManager.createSaver(containerURL: containerURL, filename: CurrentLoader.messagesFilename, fileManager: environment.fileManager)
        self.messageManager.attachmentManager = AttachmentManager(fileManager: environment.fileManager, requestor: URLSession.shared, cacheContainerURL: cacheURL, savedContainerURL: containerURL)

        if self.conversationNeedsLoading {
            CurrentLoader.loadLatestVersion(containerURL: containerURL, environment: environment) { loader in
                try self.loadConversation(from: loader)
                try self.payloadSender.load(from: loader)
                try self.messageManager.load(from: loader)
            }

            if let registerCompletion = self.registerCompletion {
                self.registerNewConversationIfNeeded(completion: registerCompletion)
            }
        } else {
            ApptentiveLogger.default.info("In-memory conversation already contains data from any saved conversation.")
        }

        // Because of potentially unbalanced calls to `load(containerURL:environment)` and `unload()`,
        // we suspend (but don't discard) the persistence timer. Therefore it should only be created once.
        if self.persistenceTimer == nil {
            self.startPersistenceTimer()
        }
    }

    /// Loads the conversation using the specified loader.
    /// - Parameter loader: The loader that translates the stored conversation to the current format, if needed.
    /// - Throws: An error if loading or merging the conversation fails.
    private func loadConversation(from loader: Loader) throws {
        let previousConversation = try loader.loadConversation()

        self.conversationNeedsLoading = false
        self.lastSyncedConversation = previousConversation
        self.conversation = try previousConversation.merged(with: self.conversation)

        self.payloadSender.credentialsProvider = self.conversation
        self.syncConversationWithAPI()

        if self.conversation != previousConversation {
            self.conversationNeedsSaving = true
        }

        try self.saveConversationIfNeeded()
    }

    private func presentInteraction(_ interaction: Interaction, completion: ((Result<Bool, Error>) -> Void)?) throws {
        guard let frontend = self.frontend else {
            throw ApptentiveError.internalInconsistency
        }

        DispatchQueue.main.async {
            do {
                try frontend.interactionPresenter.presentInteraction(interaction)

                completion?(.success(true))

                self.queue.async {
                    self.conversation.interactions.invoke(for: interaction.id)
                }
            } catch let error {
                completion?(.failure(error))
                ApptentiveLogger.default.error("Interaction presentation error: \(error)")
                apptentiveCriticalError("Interaction presentation error: \(error)")
            }
        }
    }

    /// If registered, sends updates to person, device, and app release if they have changed since the last sync.
    ///
    /// Would be private but needs to be internal for testing.
    internal func syncConversationWithAPI() {
        guard self.isRegistered else {
            ApptentiveLogger.network.debug("Skipping API sync: Not yet registered.")
            return
        }

        guard let lastSyncedConversation = self.lastSyncedConversation else {
            ApptentiveLogger.network.debug("Skipping API sync: No previously synced conversation.")
            return
        }

        self.getInteractionsIfNeeded()

        self.getConfigurationIfNeeded()

        self.getMessagesIfNeeded()

        if lastSyncedConversation.appRelease != conversation.appRelease {
            ApptentiveLogger.network.debug("App release data changed. Enqueueing update.")
            self.payloadSender.send(Payload(wrapping: self.conversation.appRelease))
            self.lastSyncedConversation?.appRelease = conversation.appRelease
        }

        if lastSyncedConversation.person != conversation.person {
            ApptentiveLogger.network.debug("Person data changed. Enqueueing update.")
            self.payloadSender.send(Payload(wrapping: self.conversation.person))
            self.lastSyncedConversation?.person = conversation.person
        }

        if lastSyncedConversation.device != conversation.device {
            ApptentiveLogger.network.debug("Device data changed. Enqueueing update.")
            self.payloadSender.send(Payload(wrapping: self.conversation.device))

            if lastSyncedConversation.device.localeRaw != self.conversation.device.localeRaw {
                ApptentiveLogger.engagement.debug("Locale changed. Invalidating engagement manifest.")
                self.invalidateEngagementManifest()
            }

            self.lastSyncedConversation?.device = conversation.device
        }
    }

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

    /// Saves the conversation to persistent storage.
    private func saveConversationIfNeeded() throws {
        if let saver = self.conversationSaver, self.conversationNeedsSaving {
            try saver.save(self.conversation)
            self.conversationNeedsSaving = false
        }
    }

    // MARK: Persistence timer

    private func startPersistenceTimer() {
        let persistenceTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        persistenceTimer.schedule(deadline: .now(), repeating: .seconds(10), leeway: .seconds(1))
        persistenceTimer.setEventHandler { [weak self] in
            ApptentiveLogger.default.debug("Running periodic housekeeping task")
            self?.syncConversationWithAPI()
            self?.saveToPersistentStorageIfNeeded()
        }

        persistenceTimer.resume()

        self.persistenceTimer = persistenceTimer
        self.persistenceTimerActive = true
    }

    private func resumePersistenceTimer() {
        if !persistenceTimerActive {
            self.persistenceTimer?.resume()
            self.persistenceTimerActive = true
        }
    }

    private func suspendPersistenceTimer() {
        if persistenceTimerActive {
            self.persistenceTimer?.suspend()
            self.persistenceTimerActive = false
        }
    }

    /// Creates a conversation on the Apptentive server using the API.
    private func postConversation(completion: @escaping (Result<Conversation.ConversationCredentials, Error>) -> Void) {
        ApptentiveLogger.default.info("Creating a new conversation via Apptentive API.")

        self.requestRetrier.startUnlessUnderway(ApptentiveV9API.createConversation(self.conversation), identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            switch result {
            case .success(let conversationResponse):
                completion(.success(Conversation.ConversationCredentials(token: conversationResponse.token, id: conversationResponse.id)))

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Retrieves a message list from the Apptentive API.
    internal func getMessagesIfNeeded() {
        if self.messageManager.messagesNeedDownloading {
            self.requestRetrier.startUnlessUnderway(ApptentiveV9API.getMessages(with: self.conversation, afterMessageWithID: self.messageManager.lastDownloadedMessageID), identifier: "get messages") { (result: Result<MessagesResponse, Error>) in
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
    private func getInteractionsIfNeeded() {
        // Check that the engagement manifest in memory (if any) is expired.
        if (self.targeter.engagementManifest.expiry ?? Date.distantPast) < Date() {
            ApptentiveLogger.default.info("Requesting new engagement manifest via Apptentive API (current one is absent or stale).")

            self.requestRetrier.startUnlessUnderway(ApptentiveV9API.getInteractions(with: self.conversation), identifier: "get interactions") { (result: Result<EngagementManifest, Error>) in
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
    private func getConfigurationIfNeeded() {
        // Check that the configuration in memory (if any) is expired.
        if (self.configuration?.expiry ?? Date.distantPast) < Date() {
            ApptentiveLogger.default.info("Requesting new app configuration via Apptentive API (current one is absent or stale).")

            self.requestRetrier.startUnlessUnderway(ApptentiveV9API.getConfiguration(with: self.conversation), identifier: "get configuration") { (result: Result<Configuration, Error>) in
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

    /// Creates a container directory if does not already exist.
    /// - Parameters:
    ///   - containerURL: The URL at which the directory should reside.
    ///   - fileManager: The `FileManager` object used to create the directory.
    /// - Throws: An error if the directory can't be created, or if an existing file is in the way of the directory.
    private func createDirectoryIfNeeded(containerURL: URL, fileManager: FileManager) throws {
        var isDirectory: ObjCBool = false

        if !fileManager.fileExists(atPath: containerURL.path, isDirectory: &isDirectory) {
            ApptentiveLogger.default.debug("Creating directory for Apptentive SDK data at \(containerURL).")

            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
        } else if !isDirectory.boolValue {
            throw ApptentiveError.fileExistsAtContainerDirectoryPath
        }
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
