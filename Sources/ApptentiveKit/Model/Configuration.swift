//
//  Configuration.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/6/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

struct Configuration: Decodable, Expiring {
    let supportName: String?
    let supportEmail: String?
    let supportImageURL: URL
    let hideBranding: Bool
    let messageCenter: MessageCenter
    let enableMessageCenter: Bool
    let enableMetrics: Bool
    let useApptimizeIntegration: Bool
    let collectAdvertisingID: Bool

    var expiry: Date?

    enum CodingKeys: String, CodingKey {
        case supportName = "support_display_name"
        case supportEmail = "support_display_email"
        case supportImageURL = "support_image_url"
        case hideBranding = "hide_branding"
        case messageCenter = "message_center"
        case enableMessageCenter = "message_center_enabled"
        case enableMetrics = "metrics_enabled"
        case useApptimizeIntegration = "apptimize_integration"
        case collectAdvertisingID = "collect_ad_id"
    }

    struct MessageCenter: Decodable {
        let title: String
        let foregroundPollingInterval: TimeInterval
        let backgroundPollingInterval: TimeInterval
        let requireEmail: Bool
        let notificationPopup: NotificationPopup

        enum CodingKeys: String, CodingKey {
            case title
            case foregroundPollingInterval = "fg_poll"
            case backgroundPollingInterval = "bg_poll"
            case requireEmail = "email_required"
            case notificationPopup = "notification_popup"
        }

        struct NotificationPopup: Decodable {
            let isEnabled: Bool

            enum CodingKeys: String, CodingKey {
                case isEnabled = "enabled"
            }
        }
    }
}
