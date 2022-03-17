//
//  Apptentive+InteractionDelegate.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/4/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

extension Apptentive {

    // MARK: ResponseSending

    func send(surveyResponse: SurveyResponse) {
        ApptentiveLogger.interaction.info("Enqueueing survey response.")

        self.backendQueue.async {
            self.backend.send(surveyResponse: surveyResponse)
        }
    }

    // MARK: EventEngaging

    func engage(event: Event) {
        self.engage(event: event, from: nil)
    }

    // MARK: ReviewRequesting

    func requestReview(completion: @escaping (Bool) -> Void) {
        ApptentiveLogger.interaction.info("Requesting review from SKStoreReviewController.")

        self.environment.requestReview(completion: completion)
    }

    // MARK: URLOpening

    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        ApptentiveLogger.interaction.info("Attempting to open URL \(url).")

        self.environment.open(url, completion: completion)
    }

    // MARK: InvocationInvoking

    func invoke(_ invocations: [EngagementManifest.Invocation], completion: @escaping (String?) -> Void) {
        self.backendQueue.async {
            self.backend.invoke(invocations, completion: completion)
        }
    }

    // MARK: ResponseRecording

    func recordResponse(_ answers: [Answer], for questionID: String) {
        self.backendQueue.async {
            self.backend.recordResponse(answers, for: questionID)
        }
    }

    // MARK: MessageSending

    func sendDraftMessage(completion: @escaping (Result<Void, Error>) -> Void) {
        self.backendQueue.async {
            completion(
                Result(catching: {
                    let (message, customData) = try self.backend.messageManager.prepareDraftMessageForSending()
                    try self.backend.sendMessage(message, with: customData)
                }))
        }
    }

    // MARK: MessageProviding

    /// Receives the message manager from the backend.
    /// - Parameter completion: A completion handler to be called when the message center view model is initialized.
    func getMessages(completion: @escaping ([MessageList.Message]) -> Void) {
        self.backendQueue.async {
            let messageList = self.backend.messageManager.messageList.messages
            DispatchQueue.main.async {
                completion(messageList)
            }
        }
    }

    var messageManagerDelegate: MessageManagerDelegate? {
        get {
            self.backend.messageManager.delegate
        }
        set {
            self.backend.messageManager.delegate = newValue
        }
    }

    func setDraftMessageBody(_ body: String?) {
        self.backendQueue.async {
            self.backend.messageManager.draftMessage.body = body
        }
    }

    func getDraftMessage(completion: @escaping (MessageList.Message) -> Void) {
        self.backendQueue.async {
            completion(self.backend.messageManager.draftMessage)
        }
    }

    // MARK: AttachmentManaging

    func addDraftAttachment(data: Data, name: String?, mediaType: String, completion: (Result<URL, Error>) -> Void) {
        // This has to block until the file is created to work with the file/photo picker API
        self.backendQueue.sync {
            completion(
                Result(catching: {
                    try self.backend.messageManager.addDraftAttachment(data: data, name: name, mediaType: mediaType)
                }))
        }
    }

    func addDraftAttachment(url: URL, completion: (Result<URL, Error>) -> Void) {
        // This has to block until the file is created to work with the file/photo picker API
        self.backendQueue.sync {
            completion(
                Result(catching: {
                    try self.backend.messageManager.addDraftAttachment(url: url)
                }))
        }
    }

    func removeDraftAttachment(at index: Int, completion: (Result<Void, Error>) -> Void) {
        self.backendQueue.sync {
            completion(
                Result(catching: {
                    try self.backend.messageManager.removeDraftAttachment(at: index)
                }))
        }
    }

    func urlForAttachment(at index: Int, in message: MessageList.Message) -> URL? {
        guard let attachmentManager = self.backend.messageManager.attachmentManager else {
            return nil
        }

        return attachmentManager.url(for: message.attachments[index])
    }

    func loadAttachment(at index: Int, in message: MessageList.Message, completion: @escaping (Result<URL, Error>) -> Void) {
        self.backendQueue.async {
            self.backend.messageManager.loadAttachment(at: index, in: message, completion: completion)
        }
    }

    // MARK: UnreadMessageUpdating

    func markMessageAsRead(_ nonce: String) {
        self.backendQueue.async {
            do {
                try self.backend.messageManager.updateReadMessage(with: nonce)
            } catch {
                ApptentiveLogger.default.error("Error updating read message in backend.")
            }
        }
    }

    // Note: ProfileUpdating is public (stored) properties and thus not present here.
}
