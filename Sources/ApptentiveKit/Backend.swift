//
//  Backend.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// The backend includes internal top-level methods used by the SDK.
///
/// It is implemented as a separate class from `Apptentive` to help enforce the main queue/background queue separation.
class Backend {
    /// The private background queue used for executing methods in this class.
    let queue: DispatchQueue

    /// The `Apptentive` instance that owns this `Backend` instance.
    weak var frontend: Apptentive?

    /// A Message Manager object which is initialized on launch.
    public var messageManager: MessageManager

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
            self.processChanges(from: oldValue)
        }
    }

    /// The file repository used to load and save the conversation from/to persistent storage.
    private var conversationRepository: PropertyListRepository<Conversation>?

    /// The object that determines whether an interaction should be presented when an event is engaged.
    private var targeter: Targeter

    private var payloadSender: PayloadSender

    private var requestRetrier: HTTPRequestRetrier

    private var configuration: Configuration?

    /// The completion handler that should be called when conversation credentials are loaded/retrieved.
    private var connectCompletion: ((Result<ConnectionType, Error>) -> Void)?

    /// Whether the conversation has changes that need to be saved to persistent storage.
    private var conversationNeedsSaving: Bool = false

    /// Whether the conversation in memory is a temporary one that should be merged with one loaded from disk.
    private var conversationNeedsLoading: Bool = true

    /// A timer that periodically runs a task to save the conversation and payload sender.
    private var persistenceTimer: DispatchSourceTimer?

    /// A flag indicating whether the persistenc timer is active.
    private var persistenceTimerActive = false

    /// The interval at which to poll for new messages.
    private var messagePollingInterval: TimeInterval {
        // TODO: Use foregroundPollingInterval when MC is presented
        return self.configuration?.messageCenter.backgroundPollingInterval ?? 600
    }

    /// Initializes a new backend instance.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - environment: The environment object used to initialize the conversation.
    ///   - baseURL: The URL where the Apptentive API is based.
    convenience init(queue: DispatchQueue, environment: ConversationEnvironment, baseURL: URL) {
        let conversation = Conversation(environment: environment)
        let client = HTTPClient(requestor: URLSession(configuration: Self.urlSessionConfiguration), baseURL: baseURL, userAgent: ApptentiveV9API.userAgent(sdkVersion: environment.sdkVersion))
        let requestRetrier = HTTPRequestRetrier(retryPolicy: HTTPRetryPolicy(), client: client, queue: queue)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier)

        self.init(queue: queue, conversation: conversation, targeter: Targeter(), messageManager: MessageManager(), requestRetrier: requestRetrier, payloadSender: payloadSender)
    }

    /// This initializer intended for testing only.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - conversation: The conversation that the backend should start with.
    ///   - targeter: The targeter to use to determine if events should show an interaction.
    ///   - messageManager: The message manager to use to manage messages for Message Center.
    ///   - requestRetrier: The Apptentive API request retrier to use to send API requests.
    ///   - payloadSender: The payload sender to use to send updates to the API.
    init(queue: DispatchQueue, conversation: Conversation, targeter: Targeter, messageManager: MessageManager, requestRetrier: HTTPRequestRetrier, payloadSender: PayloadSender) {
        self.queue = queue
        self.conversation = conversation
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
    ///   - completion: A completion handler to be called when conversation credentials are loaded/retrieved, or when loading/retrieving fails.
    func connect(appCredentials: Apptentive.AppCredentials, completion: @escaping (Result<ConnectionType, Error>) -> Void) {
        guard self.conversation.appCredentials == nil || self.conversation.appCredentials == appCredentials else {
            assertionFailure("Mismatched Credentials: Please delete and reinstall the app.")
            return
        }

        self.connectCompletion = completion

        self.conversation.appCredentials = appCredentials
    }

    /// Sets up access to persistent storage and loads any previously-saved conversation data if needed.
    ///
    /// This method may be called multiple times if the device is locked with the app in the foreground and then unlocked.
    /// - Parameters:
    ///   - containerURL: A file URL corresponding to the container directory for Apptentive files.
    ///   - environment: An object implementing the `GlobalEnvironment` protocol.
    /// - Throws: An error if the conversation file exists but can't be read, or if the saved conversation can't be merged with the in-memory conversation.
    func protectedDataDidBecomeAvailable(containerURL: URL, environment: GlobalEnvironment) throws {
        try self.createContainerDirectoryIfNeeded(containerURL: containerURL, fileManager: environment.fileManager)

        self.conversationRepository = PropertyListRepository<Conversation>(containerURL: containerURL, filename: "Conversation", fileManager: environment.fileManager)
        self.payloadSender.repository = PayloadSender.createRepository(containerURL: containerURL, filename: "PayloadQueue", fileManager: environment.fileManager)
        self.messageManager.messageListRepository = MessageManager.createRepository(containerURL: containerURL, filename: "MessageList", fileManager: environment.fileManager)

        // On the first call to `protectedDataDidBecomeAvailable(containerURL:environment:)`, update the in-memory conversation with data from any saved conversation.
        try self.updateWithSavedConversationIfNeeded(containerURL: containerURL, environment: environment)

        // Because of potentially unbalanced calls to `load(containerURL:environment)` and `unload()`,
        // we suspend (but don't discard) the persistence timer. Therefore it should only be created once.
        if self.persistenceTimer == nil {
            self.startPersistenceTimer()
        }
    }

    /// Reliquishes access to persistent storage.
    ///
    /// Called when the device is locked with the app in the foreground.
    func protectedDataWillBecomeUnavailable() {
        self.messageManager.messageListRepository = nil
        self.payloadSender.repository = nil
        self.conversationRepository = nil
    }

    func willEnterForeground(environment: GlobalEnvironment) {
        self.invalidateEngagementManifestForDebug(environment: environment)
        self.payloadSender.resume()
        self.resumePersistenceTimer()
    }

    func didEnterBackground(environment: GlobalEnvironment) {
        environment.startBackgroundTask()

        self.payloadSender.drain {
            DispatchQueue.main.async {
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
                assertionFailure("Targeting error: \(error)")
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
                    assertionFailure("TextModal button had no invocations with matching criteria.")
                case .failure(let error):
                    ApptentiveLogger.default.error("Failure presenting interaction based on invocations: \(error).")
                }
            }
        } catch let error {
            DispatchQueue.main.async {
                completion(nil)
            }

            ApptentiveLogger.interaction.error("TextModal button targeting error: \(error).")
            assertionFailure("TextModal button targeting error: \(error).")
        }
    }

    func recordResponse(_ answers: [Answer], for questionID: String) {
        self.conversation.interactions.invoke(for: questionID, with: answers)
    }

    /// Queues the specified message to be sent by the payload sender.
    /// - Parameter message: The message to send.
    func sendMessage(_ message: Message) {
        self.payloadSender.send(Payload(wrapping: message), persistEagerly: true)
    }

    /// Updates the in-memory conversation with the contents of a saved current or legacy conversation the first time it is called.
    ///
    /// Subsequent calls will have no effect.
    /// - Parameters:
    ///   - containerURL: The URL for the directory in which to look for the legacy conversation file.
    ///   - environment: The Environment object used by the legacy conversation repository migration process.
    /// - Throws: An error if the conversation file exists but can't be read, or if the saved conversation can't be merged with the in-memory conversation.
    private func updateWithSavedConversationIfNeeded(containerURL: URL, environment: GlobalEnvironment) throws {
        if self.conversationNeedsLoading {
            guard let conversationRepository = self.conversationRepository else {
                throw ApptentiveError.internalInconsistency
            }

            if conversationRepository.fileExists {
                ApptentiveLogger.default.info("Loading previously-saved conversation.")

                let savedConversation = try conversationRepository.load()

                self.conversation = try savedConversation.merged(with: self.conversation)

                self.processChanges(from: savedConversation)
            } else {
                let legacyConversationRepository = LegacyConversationRepository(containerURL: containerURL, filename: "conversation-v1.meta", environment: environment)

                if legacyConversationRepository.fileExists {
                    ApptentiveLogger.default.info("Loading legacy conversation.")

                    let legacyConversation = try legacyConversationRepository.load()

                    self.conversation = try legacyConversation.merged(with: self.conversation)

                    self.processChanges(from: legacyConversation)
                } else {
                    ApptentiveLogger.default.info("No current or legacy conversation found. Continuing with newly-created conversation.")
                }
            }

            self.conversationNeedsLoading = false
        } else {
            ApptentiveLogger.default.info("In-memory conversation already contains data from any saved conversation.")
        }
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
                assertionFailure("Interaction presentation error: \(error)")
            }
        }
    }

    /// Reacts to any changes in the conversation.
    ///
    /// This is the main "event loop" of the SDK, and centralizes the behavior in response to changes in the conversation.
    /// - Parameter oldValue: The previous value of the conversation.
    private func processChanges(from oldValue: Conversation) {
        // Determine whether we have conversation credentials.
        if let _ = conversation.conversationCredentials, let _ = conversation.appCredentials {

            // If we have credentials but we have not called the completion block, do so.
            if let connectCompletion = self.connectCompletion {
                self.connectCompletion = nil
                DispatchQueue.main.async {
                    connectCompletion(.success(.cached))
                }
            }

            // Supply the payload sender with necessary credentials
            if payloadSender.credentialsProvider == nil {
                ApptentiveLogger.network.debug("Activating payload sender.")

                self.payloadSender.credentialsProvider = self.conversation
            }

            // Retrieve a new engagement manifest if the previous one is missing or expired.
            self.getInteractionsIfNeeded()

            // Retrieve a new app configuration if the previous one is missing or expired.
            self.getConfigurationIfNeeded()

            // Check the API for new messages if we haven't done so recently (according to messagePollingInterval).
            self.getMessagesIfNeeded()

            if self.conversation.person != oldValue.person {
                ApptentiveLogger.network.debug("Person data changed. Enqueueing update.")

                self.payloadSender.send(Payload(wrapping: self.conversation.person))
            }

            if self.conversation.device != oldValue.device {
                ApptentiveLogger.network.debug("Device data changed. Enqueueing update.")

                self.payloadSender.send(Payload(wrapping: self.conversation.device))

                if self.conversation.device.localeRaw != oldValue.device.localeRaw {
                    ApptentiveLogger.engagement.debug("Locale changed. Invalidating engagement manifest.")

                    self.invalidateEngagementManifest()
                }
            }

            if self.conversation.appRelease != oldValue.appRelease {
                ApptentiveLogger.network.debug("App release data changed. Enqueueing update.")

                self.payloadSender.send(Payload(wrapping: self.conversation.appRelease))
            }
        } else if let _ = conversation.appCredentials {
            // App credentials allow us to retrieve conversation credentials from the API.
            self.createConversationOnServer()
        }  // else we can't really do anything because we can't talk to the API.

        // Mark the conversation as needing to be saved.
        self.conversationNeedsSaving = true
    }

    /// Saves the conversation and payload queue to persistent storage if needed.
    func saveToPersistentStorageIfNeeded() {
        do {
            try self.saveConversationIfNeeded()
            try self.payloadSender.savePayloadsIfNeeded()
        } catch let error {
            ApptentiveLogger.default.error("Unable to save files to persistent storage: \(error).")
            assertionFailure("Unable to save files to persistent storage: \(error.localizedDescription)")
        }
    }

    /// Saves the conversation to persistent storage.
    private func saveConversationIfNeeded() throws {
        if let repository = self.conversationRepository, self.conversationNeedsSaving {
            try repository.save(self.conversation)
            self.conversationNeedsSaving = false
        }
    }

    private func startPersistenceTimer() {
        let persistenceTimer = DispatchSource.makeTimerSource(flags: [], queue: self.queue)
        persistenceTimer.schedule(deadline: .now(), repeating: .seconds(10), leeway: .seconds(1))
        persistenceTimer.setEventHandler { [weak self] in
            ApptentiveLogger.default.debug("Running periodic persistence task")
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
    private func createConversationOnServer() {
        ApptentiveLogger.default.info("Requesting a new conversation via Apptentive API.")

        self.requestRetrier.startUnlessUnderway(ApptentiveV9API.createConversation(self.conversation), identifier: "create conversation") { (result: Result<ConversationResponse, Error>) in
            let completion = self.connectCompletion
            self.connectCompletion = nil

            switch result {
            case .success(let conversationResponse):
                self.conversation.conversationCredentials = Conversation.ConversationCredentials(token: conversationResponse.token, id: conversationResponse.id)
                DispatchQueue.main.sync {
                    completion?(.success(.new))
                }
            case .failure(let error):
                DispatchQueue.main.sync {
                    completion?(.failure(error))
                }
            }
        }
    }

    /// Retrieves a message list from the Apptentive API.
    func getMessagesIfNeeded() {
        if ((self.messageManager.lastFetchDate ?? Date.distantPast) + self.messagePollingInterval) < Date() {
            self.requestRetrier.startUnlessUnderway(ApptentiveV9API.getMessages(with: self.conversation), identifier: "get messages") { (result: Result<MessageList, Error>) in
                switch result {
                case .success(let messageList):
                    ApptentiveLogger.default.debug("Message List received.")
                    self.messageManager.messageList = messageList
                    do {
                        try self.messageManager.saveMessagesToDisk()
                    } catch let error {
                        ApptentiveLogger.default.error("Unable to save messages to disk: \(error)")
                    }
                case .failure(let error):
                    ApptentiveLogger.network.error("Failed to download message list: \(error)")
                }
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

    /// Creates a container directory if does not already exist.
    /// - Parameters:
    ///   - containerURL: The URL at which the directory should reside.
    ///   - fileManager: The `FileManager` object used to create the directory.
    /// - Throws: An error if the directory can't be created, or if an existing file is in the way of the directory.
    private func createContainerDirectoryIfNeeded(containerURL: URL, fileManager: FileManager) throws {
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

        configuration.timeoutIntervalForRequest = 60  // Default is 60
        configuration.timeoutIntervalForResource = 600  // Default is 7 days (!)
        configuration.waitsForConnectivity = true

        return configuration
    }()
}
