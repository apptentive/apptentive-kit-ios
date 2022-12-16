//
//  SpyInteractionDelegate.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

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
    var message: MessageList.Message?
    var environment = MockEnvironment()
    var messageManager = MessageManager(notificationCenter: NotificationCenter.default)
    var automatedMessageBody: String?
    var matchingInvocationIndex: Int = 0
    var matchingAdvanceLogicIndex: Int = 0

    func engage(event: Event) {
        self.engagedEvent = event
    }

    func send(surveyResponse: SurveyResponse) {
        self.sentSurveyResponse = surveyResponse
    }

    func requestReview(completion: @escaping (Bool) -> Void) {
        completion(self.shouldRequestReviewSucceed)
    }

    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        self.openedURL = url
        completion(self.shouldURLOpeningSucceed)
    }

    func invoke(_ invocations: [EngagementManifest.Invocation], completion: @escaping (String?) -> Void) {
        if invocations.count > self.matchingInvocationIndex {
            completion(invocations[matchingInvocationIndex].interactionID)
        } else {
            completion(nil)
        }
    }

    func getNextPageID(for advanceLogic: [AdvanceLogic], completion: @escaping (Result<String?, Error>) -> Void) {
        if matchingAdvanceLogicIndex < advanceLogic.count {
            completion(.success(advanceLogic[matchingAdvanceLogicIndex].pageID))
        } else {
            completion(.success(nil))
        }
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

    func getMessages(completion: @escaping (MessageManager) -> Void) {
        completion(self.messageManager)
    }

    func sendMessage(_ message: MessageList.Message) {
        self.message = message
    }

    func markMessageAsRead(_ nonce: String) {
    }

    func loadAttachmentDataFromDisk() throws -> [Data] {
        let fileURL = try self.environment.applicationSupportURL().appendingPathComponent(MockEnvironment.containerName)
        let fileList = try self.environment.fileManager.contentsOfDirectory(atPath: fileURL.path)
        var attachmentURLs: [URL] = []
        fileList.forEach({
            if $0.contains("Attachment") {
                let url = fileURL.appendingPathComponent($0)
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
            let fileURL = try self.environment.applicationSupportURL().appendingPathComponent(MockEnvironment.containerName).appendingPathComponent(uniqueID).appendingPathExtension(fileExtension)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            ApptentiveLogger.default.error("Error retrieving application support url or saving attachment to disk: \(error)")
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
            let fileURL = try self.environment.applicationSupportURL().appendingPathComponent(MockEnvironment.containerName).appendingPathComponent(uniqueID).appendingPathExtension(fileExtension)
            try self.environment.fileManager.removeItem(at: fileURL)
        } catch {
            ApptentiveLogger.default.error("Error retrieving application support url or deleting attachment to disk: \(error)")
        }
    }

    func addDraftAttachment(data: Data, name: String?, mediaType: String, completion: (Result<URL, Error>) -> Void) {

    }

    func addDraftAttachment(url: URL, completion: (Result<URL, Error>) -> Void) {

    }

    func removeDraftAttachment(at index: Int, completion: (Result<Void, Error>) -> Void) {

    }

    func urlForAttachment(at index: Int, in message: MessageList.Message) -> URL? {
        return nil
    }

    func loadAttachment(at index: Int, in message: MessageList.Message, completion: @escaping (Result<URL, Error>) -> Void) {

    }

    var messageManagerDelegate: MessageManagerDelegate?

    func getMessages(completion: @escaping ([MessageList.Message]) -> Void) {
        completion([
            MessageList.Message(id: "abc", nonce: "def", body: "Test Body", attachments: [], sender: nil, sentDate: Date(), isAutomated: false, isHidden: false, status: .unread)
        ])
    }

    func setDraftMessageBody(_ body: String?) {

    }

    func getDraftMessage(completion: @escaping (MessageList.Message) -> Void) {

    }

    func sendDraftMessage(completion: @escaping (Result<Void, Error>) -> Void) {

    }

    func setAutomatedMessageBody(_ body: String?) {
        self.automatedMessageBody = body
    }

    func sendMessage(_ message: MessageList.Message, completion: ((Result<Void, Error>) -> Void)?) {

    }
}
