//
//  Apptentive+InteractionDelegate.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 3/4/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import OSLog
import UIKit

extension Apptentive {

    // MARK: ResponseSending

    func send(surveyResponse: SurveyResponse) async {
        Logger.interaction.info("Enqueueing survey response.")

        await self.backend.send(surveyResponse: surveyResponse)
    }

    // MARK: EventEngaging

    func engage(event: Event) {
        Task {
            try await self.engage(event: event, from: nil)
        }
    }

    // MARK: ReviewRequesting

    func requestReview() async throws -> Bool {
        Logger.interaction.info("Requesting review from SKStoreReviewController.")

        return try await self.environment.requestReview()
    }

    // MARK: URLOpening

    func open(_ url: URL) async -> Bool {
        Logger.interaction.info("Attempting to open URL \(url).")

        return await self.environment.open(url)
    }

    // MARK: InvocationInvoking

    func invoke(_ invocations: [EngagementManifest.Invocation]) async throws -> String {
        return try await self.backend.invoke(invocations)
    }

    // MARK: SurveyBranching

    func getNextPageID(for advanceLogic: [AdvanceLogic]) async throws -> String? {
        return try await self.backend.getNextPageID(for: advanceLogic)
    }

    // MARK: ResponseRecording

    func recordResponse(_ response: QuestionResponse, for questionID: String) async {
        await self.backend.recordResponse(response, for: questionID)
    }

    func setCurrentResponse(_ response: QuestionResponse, for questionID: String) async {
        await self.backend.setCurrentResponse(response, for: questionID)
    }

    func resetCurrentResponse(for questionID: String) async {
        await self.backend.resetCurrentResponse(for: questionID)
    }

    // MARK: MessageSending

    func sendDraftMessage() async throws {
        if let automatedMessage = try await self.backend.prepareAutomatedMessageForSending() {
            try await self.backend.sendMessage(automatedMessage, with: nil)
        }

        let (message, customData) = try await self.backend.prepareDraftMessageForSending()
        try await self.backend.sendMessage(message, with: customData)
    }

    // MARK: MessageProviding

    func getMessages() async -> ([MessageList.Message], MessageList.AttachmentContext?) {
        return (await self.backend.getMessages(), await self.backend.getAttachmentContext())
    }

    func setMessageManagerDelegate(_ messageManagerDelegate: (any MessageManagerDelegate)?) async {
        await self.backend.setMessageManagerDelegate(messageManagerDelegate)
    }

    func setDraftMessageBody(_ body: String?) async {
        await self.backend.setDraftMessageBody(body)
    }

    func getDraftMessage() async -> (MessageList.Message, MessageList.AttachmentContext?) {
        await self.backend.getDraftMessage()
    }

    func setAutomatedMessageBody(_ body: String?) async {
        await self.backend.setAutomatedMessageBody(body)
    }

    // MARK: AttachmentManaging

    func addDraftAttachment(data: Data, name: String?, mediaType: String) async throws -> URL {
        let thumbnailSize = CGSize.apptentiveThumbnail
        let thumbnailScale = CGFloat.apptentiveThumbnailScale

        return try await self.backend.addDraftAttachment(data: data, name: name, mediaType: mediaType, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
    }

    func addDraftAttachment(url: URL) async throws -> URL {
        let thumbnailSize = CGSize.apptentiveThumbnail
        let thumbnailScale = CGFloat.apptentiveThumbnailScale

        let tempURL = URL(fileURLWithPath: UUID().uuidString, relativeTo: FileManager.default.temporaryDirectory)
        try self.environment.fileManager.copyItem(at: url, to: tempURL)

        return try await self.backend.addDraftAttachment(url: url, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
    }

    func removeDraftAttachment(at index: Int) async throws {
        try await self.backend.removeDraftAttachment(at: index)
    }

    func loadAttachment(at index: Int, in message: MessageList.Message) async throws -> URL {
        let thumbnailSize = CGSize.apptentiveThumbnail
        let thumbnailScale = CGFloat.apptentiveThumbnailScale

        return try await self.backend.loadAttachment(at: index, in: message, thumbnailSize: thumbnailSize, thumbnailScale: thumbnailScale)
    }

    // MARK: UnreadMessageUpdating

    func markMessageAsRead(_ nonce: String) async throws {
        try await self.backend.updateReadMessage(with: nonce)
    }

    // Note: ProfileUpdating is public (stored) properties and thus not present here.

    // MARK: ResourceProviding

    func getImage(at url: URL, scale: CGFloat) async throws -> UIImage {
        return try await self.resourceManager.getImage(at: url, scale: scale)
    }
}
