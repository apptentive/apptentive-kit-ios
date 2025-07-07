//
//  SpyInteractionDelegate.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import OSLog
import UIKit

@testable import ApptentiveKit

class SpyInteractionDelegate: InteractionDelegate {
    var messageCenterInForeground: Bool = false

    var personEmailAddress: String?

    var personName: String?

    var engagedEvent: Event?
    var sentSurveyResponse: SurveyResponse?
    var shouldRequestReviewSucceed = true
    var shouldURLOpeningSucceed = true
    var openedURL: URL? = nil
    var lastResponse: [String: [Answer]] = [:]
    var responses: [String: [Answer]] = [:]
    var draftMessage = MessageList.Message(nonce: "abc123")
    var sentMessage: MessageList.Message?
    var environment = MockEnvironment()
    var messageManager = MessageManager(notificationCenter: NotificationCenter.default)
    var messageManagerDelegate: MessageManagerDelegate?
    var automatedMessageBody: String?
    var matchingInvocationIndex: Int = 0
    var matchingAdvanceLogicIndex: Int = 0
    var prefetchedImage: UIImage?
    var attachmentContext = MessageList.AttachmentContext(cacheContainerURL: URL(fileURLWithPath: "/tmp"), savedContainerURL: URL(fileURLWithPath: "/tmp"))

    func addDraftAttachment(data: Data, name: String?, mediaType: String) async throws -> URL {
        return URL(fileURLWithPath: "/tmp")
    }

    func addDraftAttachment(url: URL) async throws -> URL {
        return URL(fileURLWithPath: "/tmp")
    }

    func removeDraftAttachment(at index: Int) async throws {
    }

    func loadAttachment(at index: Int, in message: ApptentiveKit.MessageList.Message) async throws -> URL {
        return URL(fileURLWithPath: "/tmp")
    }

    func invoke(_ invocations: [ApptentiveKit.EngagementManifest.Invocation]) async throws -> String {
        if invocations.count > self.matchingInvocationIndex {
            return invocations[matchingInvocationIndex].interactionID
        } else {
            throw ApptentiveError.internalInconsistency
        }
    }

    func getMessages() async -> ([ApptentiveKit.MessageList.Message], ApptentiveKit.MessageList.AttachmentContext?) {
        let message = MessageList.Message(id: "abc", nonce: "def", body: "Test Body", attachments: [], sender: nil, sentDate: Date(), isAutomated: false, isHidden: false, status: .unread)
        return ([message], self.attachmentContext)
    }

    func getDraftMessage() async -> (ApptentiveKit.MessageList.Message, ApptentiveKit.MessageList.AttachmentContext?) {
        return (self.draftMessage, self.attachmentContext)
    }

    func sendDraftMessage() async throws {
        self.sentMessage = self.draftMessage
    }

    func setAutomatedMessageBody(_ body: String?) {
        self.automatedMessageBody = body
    }

    func setDraftMessageBody(_ body: String?) {
        self.draftMessage.body = body
    }

    func markMessageAsRead(_ nonce: String) {
    }

    func setMessageManagerDelegate(_ messageManagerDelegate: (any ApptentiveKit.MessageManagerDelegate)?) {
        self.messageManagerDelegate = messageManagerDelegate
    }

    func getImage(at url: URL, scale: CGFloat) async throws -> UIImage {
        if let prefetchedImage = self.prefetchedImage {
            return prefetchedImage
        } else {
            throw ApptentiveError.resourceNotDecodableAsImage
        }
    }

    func requestReview() async throws -> Bool {
        return self.shouldRequestReviewSucceed
    }

    func getNextPageID(for advanceLogic: [ApptentiveKit.AdvanceLogic]) async throws -> String? {
        if matchingAdvanceLogicIndex < advanceLogic.count {
            return advanceLogic[matchingAdvanceLogicIndex].pageID
        } else {
            return nil
        }
    }

    func open(_ url: URL) async -> Bool {
        self.openedURL = url
        return self.shouldURLOpeningSucceed
    }

    func engage(event: Event) {
        self.engagedEvent = event
    }

    func send(surveyResponse: SurveyResponse) {
        self.sentSurveyResponse = surveyResponse
    }

    func recordResponse(_ response: QuestionResponse, for questionID: String) {
        if case .answered(let answers) = response {
            lastResponse[questionID] = answers

            var questionResponses = responses[questionID] ?? []
            questionResponses.append(contentsOf: answers)
            responses[questionID] = questionResponses
        }
    }

    func setCurrentResponse(_ response: QuestionResponse, for questionID: String) {
        if case .answered(let answers) = response {
            lastResponse[questionID] = answers
        }
    }

    func resetCurrentResponse(for questionID: String) {
        self.lastResponse[questionID] = nil
    }

    func loadAttachmentDataFromDisk() throws -> [Data] {
        let fileURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(MockEnvironment.containerName)
        let fileList = try self.environment.fileManager.contentsOfDirectory(at: fileURL)
        var attachmentURLs: [URL] = []
        fileList.forEach({
            if $0.path.contains("Attachment") {
                let url = fileURL.appendingPathComponent($0.path)
                attachmentURLs.append(url)

            }
        })
        var attachmentData: [Data] = []
        try attachmentURLs.forEach({
            let data = try Data(contentsOf: $0)
            attachmentData.append(data)
        })
        return attachmentData
    }

    func saveAttachmentToDisk(fileName: String, index: Int, mediaType: String, data: Data) {
        let uniqueID = "\(index)-\(fileName)"
        var fileExtension = ""

        if mediaType.contains("image") {
            fileExtension = "png"
        } else {
            fileExtension = String(mediaType.suffix(3))
        }

        do {
            let fileURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(MockEnvironment.containerName).appendingPathComponent(uniqueID).appendingPathExtension(fileExtension)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            Logger.default.error("Error retrieving application support url or saving attachment to disk: \(error)")
        }
    }

    func deleteAttachmentFromDisk(fileName: String, index: Int, mediaType: String) {
        let uniqueID = "\(index)-\(fileName)"
        var fileExtension = ""

        if mediaType.contains("image") {
            fileExtension = "png"
        } else {
            fileExtension = String(mediaType.suffix(3))
        }
        do {
            let fileURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(MockEnvironment.containerName).appendingPathComponent(uniqueID).appendingPathExtension(fileExtension)
            try self.environment.fileManager.removeItem(at: fileURL)
        } catch {
            Logger.default.error("Error retrieving application support url or deleting attachment to disk: \(error)")
        }
    }
}
