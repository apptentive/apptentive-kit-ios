//
//  Backend.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

class Backend {
    let queue: DispatchQueue
    weak var frontend: Apptentive?

    enum ConnectionType {
        case cached
        case new
    }

    private var conversation: Conversation {
        didSet {
            self.processChanges()
        }
    }

    private var client: HTTPClient<ApptentiveV9API>?
    private var conversationRepository: ConversationRepository?
    private var targeter: Targeter

    private var createConversationTask: HTTPCancellable?
    private var getInteractionsTask: HTTPCancellable?

    private var connectCompletion: ((Result<ConnectionType, Error>) -> Void)?

    init(queue: DispatchQueue, environment: Environment) {
        self.queue = queue
        self.conversation = Conversation(environment: environment)
        self.targeter = Targeter()
    }

    func connect(appCredentials: Apptentive.AppCredentials, baseURL: URL, completion: @escaping (Result<ConnectionType, Error>) -> Void) {
        guard self.conversation.appCredentials == nil || self.conversation.appCredentials == appCredentials else {
            completion(.failure(ApptentiveError.mismatchedCredentials))
            return
        }

        self.connectCompletion = completion

        self.client = HTTPClient(requestor: URLSession.shared, baseURL: baseURL)

        self.conversation.appCredentials = appCredentials
    }

    func load(containerURL: URL, fileManager: FileManager) throws {
        try self.createContainerDirectoryIfNeeded(containerURL: containerURL, fileManager: fileManager)

        let conversationRepository = ConversationRepository(containerURL: containerURL, fileManager: fileManager)
        self.conversationRepository = conversationRepository

        if conversationRepository.fileExists {
            let savedConversation = try conversationRepository.load()

            self.conversation = try savedConversation.merged(with: self.conversation)
        }
    }

    func engage(event: Event, completion: ((Bool) -> Void)?) {
        do {
            if let interaction = try self.targeter.interactionData(for: event) {
                guard let frontend = self.frontend else {
                    throw ApptentiveError.internalInconsistency
                }

                DispatchQueue.main.async {
                    do {
                        try frontend.interactionPresenter.presentInteraction(interaction)

                        completion?(true)
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

    func send(surveyResponse: SurveyResponse) {
        // TODO: use some kind of payload sending queue so we don't have to do this check
        guard let client = self.client else {
            return assertionFailure("Attempting to send survey response before connect was called.")
        }

        client.request(.createSurveyResponse(surveyResponse, for: conversation)) { (result: Result<PayloadResponse, Error>) in
            self.queue.async {
                switch result {
                case .success:
                    print("Successfully sent survey response")
                case .failure(let error):
                    print("Error sending survey response: \(error)")
                    print("This is where we would retry the request.")
                }
            }
        }
    }

    private func processChanges() {
        if let _ = conversation.conversationCredentials {
            if let connectCompletion = self.connectCompletion {
                connectCompletion(.success(.cached))
                self.connectCompletion = nil
            }

            self.getInteractionsIfNeeded()
        } else if let _ = conversation.appCredentials {
            self.createConversationIfNeeded()
        }  // we have no saved conversation credentials and app hasn't called "Connect" yet.
        if let repository = self.conversationRepository {
            do {
                try repository.save(self.conversation)
            } catch let error {
                assertionFailure("Unable to save conversation: \(error)")
            }
        }
    }

    private func createConversationIfNeeded() {
        if self.createConversationTask == nil {
            self.createConversationTask = self.client?.request(.createConversation(self.conversation)) { (result: Result<ConversationResponse, Error>) in
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

    private func getInteractionsIfNeeded() {
        if self.getInteractionsTask == nil && (self.targeter.engagementManifest.expiry ?? Date.distantPast) < Date() {
            self.getInteractionsTask = self.client?.request(.getInteractions(for: self.conversation)) { (result: Result<EngagementManifest, Error>) in
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

    private func createContainerDirectoryIfNeeded(containerURL: URL, fileManager: FileManager) throws {
        var isDirectory: ObjCBool = false

        if !fileManager.fileExists(atPath: containerURL.path, isDirectory: &isDirectory) {
            try fileManager.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
        } else if !isDirectory.boolValue {
            throw ApptentiveError.fileExistsAtContainerDirectoryPath
        }
    }
}
