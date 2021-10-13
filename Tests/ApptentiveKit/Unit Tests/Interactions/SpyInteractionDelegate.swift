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

    var engagedEvent: Event?
    var sentSurveyResponse: SurveyResponse?
    var shouldRequestReviewSucceed = true
    var shouldURLOpeningSucceed = true
    var openedURL: URL? = nil
    var responses: [String: [Answer]] = [:]
    var termsOfService: TermsOfService?
    var messageList: MessageList?

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

    func getMessages(completion: @escaping (MessageList) -> Void) {
        guard let messageList = self.messageList else { return }
        completion(messageList)
    }

    func sendMessage(_ message: Message) {
        self.messageList?.messages.append(message)
    }
}
