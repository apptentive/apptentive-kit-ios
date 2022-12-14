//
//  MessageCenterConfiguration.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// An object corresponding to the `configuration` object in an interaction of type `MessageCenter`.
///
/// This object is intended to faithfully represent the data retrieved as part
/// of the engagement manfiest. The view model receives this object in its initializer and then sets these values in the MesssageCenterViewModel.
struct MessageCenterConfiguration: Codable {
    let title: String
    let branding: String?
    let composer: Composer
    let greeting: Greeting
    let status: Status
    let automatedMessage: AutomatedMessage?
    let errorMessages: ErrorMessages
    let profile: Profile

    enum CodingKeys: String, CodingKey {
        case title, branding, composer, greeting, status
        case automatedMessage = "automated_message"
        case errorMessages = "error_messages"
        case profile
    }

    struct AutomatedMessage: Codable {
        let body: String?
    }

    struct Composer: Codable {
        let title, hintText, sendButton, sendStart: String
        let sendOk, sendFail, closeText, closeConfirmBody: String
        let closeDiscardButton, closeCancelButton: String

        enum CodingKeys: String, CodingKey {
            case title
            case hintText = "hint_text"
            case sendButton = "send_button"
            case sendStart = "send_start"
            case sendOk = "send_ok"
            case sendFail = "send_fail"
            case closeText = "close_text"
            case closeConfirmBody = "close_confirm_body"
            case closeDiscardButton = "close_discard_button"
            case closeCancelButton = "close_cancel_button"
        }
    }

    struct ErrorMessages: Codable {
        let httpErrorBody, networkErrorBody: String?

        enum CodingKeys: String, CodingKey {
            case httpErrorBody = "http_error_body"
            case networkErrorBody = "network_error_body"
        }
    }

    struct Greeting: Codable {
        let title, body: String
        let imageURL: URL

        enum CodingKeys: String, CodingKey {
            case title, body
            case imageURL = "image_url"
        }
    }

    struct Profile: Codable {
        let request, require: Bool
        let initial: Initial
        let edit: Edit
    }

    struct Initial: Codable {
        let title, nameHint, emailHint, skipButton, saveButton: String
        let emailExplanation: String?

        enum CodingKeys: String, CodingKey {
            case title
            case nameHint = "name_hint"
            case emailHint = "email_hint"
            case skipButton = "skip_button"
            case saveButton = "save_button"
            case emailExplanation = "email_explanation"
        }
    }

    struct Edit: Codable {
        let title, nameHint, emailHint, skipButton, saveButton: String

        enum CodingKeys: String, CodingKey {
            case title
            case nameHint = "name_hint"
            case emailHint = "email_hint"
            case skipButton = "skip_button"
            case saveButton = "save_button"
        }
    }

    struct Status: Codable {
        let body: String?
    }
}
