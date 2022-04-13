//
//  Apptentive+NotificationName.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 3/17/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let payloadEnqueued = Notification.Name("com.apptentive.payloadEnqueued")
    static let payloadSending = Notification.Name("com.apptentive.payloadSending")
    static let payloadSent = Notification.Name("com.apptentive.payloadSent")
    static let payloadFailed = Notification.Name("com.apptentive.payloadFailed")
    /// The notification name to use to post and observe a notification when an event is engaged.
    public static let apptentiveEventEngaged = Notification.Name("com.apptentive.apptentiveEventEngaged")
}
