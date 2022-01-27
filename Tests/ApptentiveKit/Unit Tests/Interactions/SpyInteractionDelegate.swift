//
//  SpySender.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

@testable import ApptentiveKit

class SpyInteractionDelegate: InteractionDelegate {

    var messageCenterInForeground: Bool = false

    var engagedEvent: Event?
    var sentSurveyResponse: SurveyResponse?
    var shouldRequestReviewSucceed = true
    var shouldURLOpeningSucceed = true
    var openedURL: URL? = nil
    var responses: [String: [Answer]] = [:]
    var termsOfService: TermsOfService?
    var message: OutgoingMessage?
    var environment = MockEnvironment()
    var messageManager = MessageManager(notificationCenter: NotificationCenter.default)

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
        completion(invocations.first?.interactionID)
    }

    func recordResponse(_ answers: [Answer], for questionID: String) {
        responses[questionID] = answers
    }

    func getMessages(completion: @escaping (MessageManager) -> Void) {
        completion(self.messageManager)
    }

    func sendMessage(_ message: OutgoingMessage) {
        self.message = message
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
}
