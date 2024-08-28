//
//  Apptentive+InteractionDelegate.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/4/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

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

    // MARK: SurveyBranching

    func getNextPageID(for advanceLogic: [AdvanceLogic], completion: @escaping (Result<String?, Error>) -> Void) {
        self.backendQueue.async {
            self.backend.getNextPageID(for: advanceLogic, completion: completion)
        }
    }

    // MARK: ResponseRecording

    func recordResponse(_ response: QuestionResponse, for questionID: String) {
        self.backendQueue.async {
            self.backend.recordResponse(response, for: questionID)
        }
    }

    func setCurrentResponse(_ response: QuestionResponse, for questionID: String) {
        self.backendQueue.async {
            self.backend.setCurrentResponse(response, for: questionID)
        }
    }

    func resetCurrentResponse(for questionID: String) {
        self.backendQueue.async {
            self.backend.resetCurrentResponse(for: questionID)
        }
    }

    // MARK: MessageSending

    func sendDraftMessage(completion: @escaping (Result<Void, Error>) -> Void) {
        self.backendQueue.async {
            completion(
                Result(catching: {
                    if let automatedMessage = try self.backend.prepareAutomatedMessageForSending() {
                        try self.backend.sendMessage(automatedMessage)
                    }

                    let (message, customData) = try self.backend.prepareDraftMessageForSending()
                    try self.backend.sendMessage(message, with: customData)
                }))
        }
    }

    // MARK: MessageProviding

    /// Receives the message manager from the backend.
    /// - Parameter completion: A completion handler to be called when the message center view model is initialized.
    func getMessages(completion: @escaping ([MessageList.Message]) -> Void) {
        self.backendQueue.async {
            completion(self.backend.messageManager.messages)
        }
    }

    func setMessageManagerDelegate(_ messageManagerDelegate: MessageManagerDelegate?) {
        self.backendQueue.async {
            self.backend.setMessageManagerDelegate(messageManagerDelegate)
        }
    }

    func setDraftMessageBody(_ body: String?) {
        self.backendQueue.async {
            self.backend.setDraftMessageBody(body)
        }
    }

    func getDraftMessage(completion: @escaping (MessageList.Message) -> Void) {
        self.backendQueue.async {
            self.backend.getDraftMessage(completion: completion)
        }
    }

    func setAutomatedMessageBody(_ body: String?) {
        self.backendQueue.async {
            self.backend.setAutomatedMessageBody(body)
        }
    }

    // MARK: AttachmentManaging

    func addDraftAttachment(data: Data, name: String?, mediaType: String, completion: (Result<URL, Error>) -> Void) {
        let thumbnailSize = CGSize.apptentiveThumbnail
        let thumbnailScale = CGFloat.apptentiveThumbnailScale

        // This has to block until the file is created to work with the file/photo picker API
        self.backendQueue.sync {
            completion(
                Result(catching: {
                    try self.backend.addDraftAttachment(data: data, name: name, mediaType: mediaType, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
                }))
        }
    }

    func addDraftAttachment(url: URL, completion: (Result<URL, Error>) -> Void) {
        let thumbnailSize = CGSize.apptentiveThumbnail
        let thumbnailScale = CGFloat.apptentiveThumbnailScale

        // This has to block until the file is created to work with the file/photo picker API
        self.backendQueue.sync {
            completion(
                Result(catching: {
                    try self.backend.addDraftAttachment(url: url, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
                }))
        }
    }

    func removeDraftAttachment(at index: Int, completion: (Result<Void, Error>) -> Void) {
        self.backendQueue.sync {
            completion(
                Result(catching: {
                    try self.backend.removeDraftAttachment(at: index)
                }))
        }
    }

    func urlForAttachment(at index: Int, in message: MessageList.Message) -> URL? {
        return self.backend.url(for: message.attachments[index])
    }

    func loadAttachment(at index: Int, in message: MessageList.Message, completion: @escaping (Result<URL, Error>) -> Void) {
        let thumbnailSize = CGSize.apptentiveThumbnail
        let thumbnailScale = CGFloat.apptentiveThumbnailScale

        self.backendQueue.async {
            self.backend.loadAttachment(at: index, in: message, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale, completion: completion)
        }
    }

    // MARK: UnreadMessageUpdating

    func markMessageAsRead(_ nonce: String) {
        self.backendQueue.async {
            do {
                try self.backend.updateReadMessage(with: nonce)
            } catch {
                ApptentiveLogger.default.error("Error updating read message in backend.")
            }
        }
    }

    // Note: ProfileUpdating is public (stored) properties and thus not present here.

    // MARK: ResourceProviding

    func getImage(at url: URL, scale: CGFloat, completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.resourceManager.getImage(at: url, scale: scale) { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}
