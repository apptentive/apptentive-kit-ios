//
//  ResponseSending.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/6/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

typealias InteractionDelegate = ResponseSending & EventEngaging & ReviewRequesting & URLOpening

/// Describes an object that can send responses from Survey interactions.
protocol ResponseSending {
    /// Sends the specified survey response to the Apptentive API.
    /// - Parameter surveyResponse: The survey response to send.
    func send(surveyResponse: SurveyResponse)
}

/// Describes an object that can engage an event.
protocol EventEngaging {
    /// Engages the specified event by including the interaction.
    /// - Parameter event: The event to engage.
    func engage(event: Event)
}

/// Describes an object that can request an App Store review.
protocol ReviewRequesting {
    /// Requests an App Store review from the system
    /// - Parameter completion: Called with a value indicating whether the review request was shown.
    func requestReview(completion: @escaping (Bool) -> Void)
}

/// Describes an object that can ask the system to open a URL.
protocol URLOpening {
    /// Asks the system to open the specified URL.
    /// - Parameters:
    ///   - url: The URL to open.
    ///   - completion: Called with a value indicating whether the URL was successfully opened.
    func open(_ url: URL, completion: @escaping (Bool) -> Void)
}
