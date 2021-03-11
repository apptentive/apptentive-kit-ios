//
//  SpySender.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 11/30/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

@testable import ApptentiveKit

class SpyInteractionDelegate: InteractionDelegate {
    var engagedEvent: Event?
    var sentSurveyResponse: SurveyResponse?
    var shouldRequestReviewSucceed = true
    var shouldURLOpeningSucceed = true
    var openedURL: URL? = nil

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
}
