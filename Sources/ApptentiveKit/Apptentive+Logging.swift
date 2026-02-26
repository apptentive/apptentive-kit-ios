//
//  Apptentive+Logging.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/15/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

extension Logger {
    private static let subsystemPrefix = (Bundle.main.bundleIdentifier ?? "com.apptentive") + ".apptentive"

    /// Logger for things that aren't really part of any other subsystem.
    public static let `default` = Logger(subsystem: subsystemPrefix, category: "default")

    /// Logger for engaging event and targeting.
    public static let engagement = Logger(subsystem: subsystemPrefix, category: "engagement")

    /// Logger for interaction-related activity.
    public static let interaction = Logger(subsystem: subsystemPrefix, category: "interaction")

    /// Logger for network-related activity.
    public static let network = Logger(subsystem: subsystemPrefix, category: "network")

    /// Logger for payload sender activity.
    public static let payload = Logger(subsystem: subsystemPrefix, category: "payload")

    /// Logger for targeting activity.
    public static let targeting = Logger(subsystem: subsystemPrefix, category: "targeting")

    /// Logger for message center messages.
    public static let messages = Logger(subsystem: subsystemPrefix, category: "messages")

    /// Logger for message center attachments.
    public static let attachments = Logger(subsystem: subsystemPrefix, category: "attachments")

    /// Logger for resource manager.
    public static let resources = Logger(subsystem: subsystemPrefix, category: "resources")
}
