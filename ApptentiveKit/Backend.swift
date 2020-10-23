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
    private var conversation: Conversation {
        didSet {
            self.processChanges()
        }
    }

    /// The REST client used to communicate with the Apptentive API.
    private var client: HTTPClient<ApptentiveV9API>

    /// The file repository used to load and save the conversation from/to persistent storage.
    private var conversationRepository: PropertyListRepository<Conversation>?

    /// The object that determines whether an interaction should be presented when an event is engaged.
    private var targeter: Targeter

    private var payloadSender: PayloadSender

    /// The network task used to create a conversation.
    private var createConversationTask: HTTPCancellable?

    /// The network task used to retrive the engagement manifest.
    private var getInteractionsTask: HTTPCancellable?

    /// The completion handler that should be called when conversation credentials are loaded/retrieved.
    private var connectCompletion: ((Result<ConnectionType, Error>) -> Void)?

    /// Initializes a new backend instance.
    /// - Parameters:
    ///   - queue: The dispatch queue on which the backend instance should run.
    ///   - environment: The environment object used to initialize the conversation.
    ///   - baseURL: The URL where the Apptentive API is based.
    init(queue: DispatchQueue, environment: Environment, baseURL: URL) {
        self.queue = queue
        self.conversation = Conversation(environment: environment)
        self.targeter = Targeter()
        self.client = HTTPClient(requestor: URLSession.shared, baseURL: baseURL)
        self.payloadSender = PayloadSender(queue: queue, client: self.client)
    }

    /// Connects the backend to the Apptentive API.
    /// - Parameters:
    ///   - appCredentials: The App Key and App Signature to use when communicating with the Apptentive API
    ///   - completion: A completion handler to be called when conversation credentials are loaded/retrieved, or when loading/retrieving fails.
    func connect(appCredentials: Apptentive.AppCredentials, completion: @escaping (Result<ConnectionType, Error>) -> Void) {
        guard self.conversation.appCredentials == nil || self.conversation.appCredentials == appCredentials else {
            completion(.failure(ApptentiveError.mismatchedCredentials))
            return
        }

        self.connectCompletion = completion

        self.conversation.appCredentials = appCredentials
    }

    /// Loads a previously saved conversation, if any, from persistent storage.
    /// - Parameters:
    ///   - containerURL: A file URL corresponding to the container directory for Apptentive files.
    ///   - fileManager: The `FileManager` instance to use when accessing the filesystem.
    /// - Throws: An error if the conversation file exists but can't be read, or if the saved conversation can't be merged with the in-memory conversation.
    func load(containerURL: URL, fileManager: FileManager) throws {
        try self.createContainerDirectoryIfNeeded(containerURL: containerURL, fileManager: fileManager)

        let conversationRepository = PropertyListRepository<Conversation>(containerURL: containerURL, filename: "Conversation", fileManager: fileManager)
        self.conversationRepository = conversationRepository

        if conversationRepository.fileExists {
            let savedConversation = try conversationRepository.load()

            self.conversation = try savedConversation.merged(with: self.conversation)
        }
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
    func engage(event: Event, completion: ((Bool) -> Void)?) {
        self.payloadSender.send(Payload(wrapping: event), for: self.conversation)

        self.conversation.codePoints.invoke(for: event.codePointName)

        do {
            if let interaction = try self.targeter.interactionData(for: event, state: self.conversation) {
                guard let frontend = self.frontend else {
                    throw ApptentiveError.internalInconsistency
                }

                DispatchQueue.main.async {
                    do {
                        try frontend.interactionPresenter.presentInteraction(interaction)

                        completion?(true)

                        self.queue.async {
                            self.conversation.interactions.invoke(for: interaction.id)
                        }
                    } catch let error {
                        completion?(false)
                        assertionFailure("Interaction presentation error: \(error)")
                    }
                }

            } else {
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        } catch let error {
            DispatchQueue.main.async {
                completion?(false)
                assertionFailure("Targeting error: \(error)")
            }
        }
    }

    /// Sends a survey response to the Apptentive API.
    /// - Parameter surveyResponse: The survey response to send to the API.
    func send(surveyResponse: SurveyResponse) {
        self.payloadSender.send(Payload(wrapping: surveyResponse), for: self.conversation)
    }

    /// Reacts to any changes in the conversation.
    ///
    /// This is the main "event loop" of the SDK, and centralizes the behavior in response to changes in the conversation.
    private func processChanges() {

        // Determine whether we have conversation credentials.
        if let _ = conversation.conversationCredentials {

            // If we have credentials but we have not called the completion block, do so.
            if let connectCompletion = self.connectCompletion {
                connectCompletion(.success(.cached))
                self.connectCompletion = nil
            }

            // Supply the payload sender with necessary credentials
            self.payloadSender.credentials = self.conversation

            // Retrieve a new engagement manifest if the previous one is missing or expired.
            self.getInteractionsIfNeeded()
        } else if let _ = conversation.appCredentials {
            // App credentials allow us to retrieve conversation credentials from the API.
            self.createConversationOnServer()
        }  // else we can't really do anything because we can't talk to the API.

        // If we have disk access, save the conversation.
        if let repository = self.conversationRepository {
            do {
                try repository.save(self.conversation)
            } catch let error {
                assertionFailure("Unable to save conversation: \(error)")
            }
        }
    }

    /// Creates a conversation on the Apptentive server using the API.
    private func createConversationOnServer() {
        // Make sure we don't have a request in flight already.
        if self.createConversationTask == nil {
            self.createConversationTask = self.client.request(.createConversation(self.conversation)) { (result: Result<ConversationResponse, Error>) in
                self.queue.async {
                    switch result {
                    case .success(let conversationResponse):
                        self.conversation.conversationCredentials = Conversation.ConversationCredentials(token: conversationResponse.token, id: conversationResponse.id)
                        self.connectCompletion?(.success(.new))
                    case .failure(let error):
                        self.connectCompletion?(.failure(error))
                    }

                    self.createConversationTask = nil
                    self.connectCompletion = nil
                }
            }
        }
    }

    /// Retrieves an engagement manifest from the Apptentive API if the current one is missing or expired.
    private func getInteractionsIfNeeded() {
        // Make sure we don't have a request in flight already, and that the engagement manifest in memory (if any) is expired.
        if self.getInteractionsTask == nil && (self.targeter.engagementManifest.expiry ?? Date.distantPast) < Date() {
            self.getInteractionsTask = self.client.request(.getInteractions(with: self.conversation)) { (result: Result<EngagementManifest, Error>) in
                self.queue.async {
                    switch result {
                    case .success(let engagementManifest):
                        self.targeter.engagementManifest = engagementManifest
                    case .failure(let error):
                        print("Failed to download engagement manifest: \(error)")
                    }

                    self.getInteractionsTask = nil
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
            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
        } else if !isDirectory.boolValue {
            throw ApptentiveError.fileExistsAtContainerDirectoryPath
        }
    }
}
