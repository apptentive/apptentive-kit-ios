//
//  InteractionDelegate.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/6/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

typealias InteractionDelegate = ResponseSending & EventEngaging & ReviewRequesting & URLOpening & InvocationInvoking & ResponseRecording & MessageSending & MessageProviding & AttachmentManaging & ProfileEditing
    & UnreadMessageUpdating & SurveyBranching & ResourceProviding & Sendable

/// Describes an object that can manage attachments to a draft message and load attachments from an arbitrary message.
@MainActor protocol AttachmentManaging: AnyObject {
    func addDraftAttachment(data: Data, name: String?, mediaType: String) async throws -> URL
    func addDraftAttachment(url: URL) async throws -> URL
    func removeDraftAttachment(at index: Int) async throws
    func loadAttachment(at index: Int, in message: MessageList.Message) async throws -> URL
}

/// Describes an object that edits the name and email of the consumer.
@MainActor protocol ProfileEditing: AnyObject {
    var personEmailAddress: String? { get set }
    var personName: String? { get set }
}

/// Describes an object that can send the unread message ID to the backend to update the unread message count.
@MainActor protocol UnreadMessageUpdating: AnyObject {
    func markMessageAsRead(_ nonce: String) async throws
}

/// Describes an object that can receive the MessageManager from the backend.
@MainActor protocol MessageProviding: AnyObject {
    func setMessageManagerDelegate(_ messageManagerDelegate: MessageManagerDelegate?) async
    func getMessages() async -> ([MessageList.Message], MessageList.AttachmentContext?)
    func setDraftMessageBody(_ body: String?) async
    func getDraftMessage() async -> (MessageList.Message, MessageList.AttachmentContext?)
    func setAutomatedMessageBody(_ body: String?) async
}

/// Describes an object that can send messages from the Message Center interaction.
@MainActor protocol MessageSending: AnyObject {
    /// Sends the draft message.
    /// - Throws: An error if the draft message fails to send.
    func sendDraftMessage() async throws
}

/// Describes an object that can send responses from Survey interactions.
@MainActor protocol ResponseSending: AnyObject {
    /// Sends the specified survey response to the Apptentive API.
    /// - Parameter surveyResponse: The survey response to send.
    func send(surveyResponse: SurveyResponse) async
}

/// Describes an object that can engage an event.
@MainActor protocol EventEngaging: AnyObject {
    /// Engages the specified event by including the interaction.
    /// - Parameter event: The event to engage.
    func engage(event: Event)
}

/// Describes an object that can process invocations and potentially display interactions.
@MainActor protocol InvocationInvoking: AnyObject {
    func invoke(_ invocations: [EngagementManifest.Invocation]) async throws -> String
}

/// Describes an object that can evaluate criteria for survey branching.
@MainActor protocol SurveyBranching: AnyObject {
    func getNextPageID(for advanceLogic: [AdvanceLogic]) async throws -> String?
}

/// Describes an object that can request an App Store review.
@MainActor protocol ReviewRequesting: AnyObject {
    /// Requests an App Store review from the system.
    /// - Throws: An error if the review request fails.
    func requestReview() async throws -> Bool
}

/// Describes an object that can ask the system to open a URL.
@MainActor protocol URLOpening: AnyObject {
    /// Asks the system to open the specified URL.
    /// - Parameter url: The URL to open.
    /// - Returns: A value indicating whether the URL could be opened.
    func open(_ url: URL) async -> Bool
}

/// Describes an object that can record a response to an interaction.
@MainActor protocol ResponseRecording: AnyObject {
    /// Records the specified response for later querying in the targeter.
    /// - Parameters:
    ///   - response: The response to the question.
    ///   - questionID: The identifier for the question.
    func recordResponse(_ response: QuestionResponse, for questionID: String) async

    /// Sets the specified response for immediate querying in the targeter (cleared if interaction canceled).
    /// - Parameters:
    ///   - response: The response to the question.
    ///   - questionID: The identifier for the question.
    func setCurrentResponse(_ response: QuestionResponse, for questionID: String) async

    /// Resets the current response to the specified question.
    /// - Parameter questionID: The identifier for the question.
    func resetCurrentResponse(for questionID: String) async
}

/// Describes an object that can provide the data downloaded from a URL (typically with pre-fetch).
@MainActor protocol ResourceProviding: AnyObject {
    func getImage(at url: URL, scale: CGFloat) async throws -> UIImage
}
