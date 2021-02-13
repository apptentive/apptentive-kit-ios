//
//  ApptentiveLogger.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/15/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

/// Intended to be not exactly a drop-in replacement, but pretty close to the iOS 14 `Logger` class.
struct ApptentiveLogger {
    private let log: OSLog

    /// Creates a logger with the specified subsystem.
    init(subsystem: String) {
        self.log = OSLog(subsystem: subsystem, category: .pointsOfInterest)
    }

    private func log(_ message: ApptentiveLogMessage, type: OSLogType) {
        os_log(type, log: self.log, "%@", message.description)
    }

    /// Logs a debug message.
    /// - Parameter message: The message to log.
    func debug(_ message: ApptentiveLogMessage) {
        self.log(message, type: .debug)
    }

    /// Log an info message.
    /// - Parameter message: The message to log.
    func info(_ message: ApptentiveLogMessage) {
        self.log(message, type: .info)
    }

    /// Log a message at the default level.
    /// - Parameter message: The message to log.
    func notice(_ message: ApptentiveLogMessage) {
        self.log(message, type: .default)
    }

    /// Log a message at the error level.
    ///
    /// Provided for compatability with the `Logger` class.
    /// - Parameter message: The message to log.
    func warning(_ message: ApptentiveLogMessage) {
        self.log(message, type: .error)
    }

    /// Log a message at the error level.
    /// - Parameter message: The message to log.
    func error(_ message: ApptentiveLogMessage) {
        self.log(message, type: .error)
    }

    /// Log a message at the fault level.
    ///
    /// Provided for compatability with the `Logger` class.
    /// - Parameter message: The message to log.
    func critcal(_ message: ApptentiveLogMessage) {
        self.log(message, type: .fault)
    }

    /// Log a message at the fault level.
    /// - Parameter message: The message to log.
    func fault(_ message: ApptentiveLogMessage) {
        self.log(message, type: .fault)
    }
}

struct ApptentiveLogMessage: LosslessStringConvertible {
    init?(_ description: String) {
        self.description = description
    }

    // Need a non-failable initializer to keep the linter happy.
    init(description: String) {
        self.description = description
    }

    var description: String
}

extension ApptentiveLogMessage: ExpressibleByStringInterpolation {
    init(stringLiteral value: String) {
        self.init(description: value)
    }

    init(stringInterpolation: StringInterpolation) {
        self.init(description: stringInterpolation.value)
    }

    struct StringInterpolation: StringInterpolationProtocol {
        var segments: [(() -> String, ApptentiveLogPrivacy)]
        var value: String {
            let isDebugging = isatty(STDERR_FILENO) != 0

            return self.segments.map { (segment, privacy) in
                switch privacy {
                case .public:
                    return segment()
                case .private, .auto:
                    return isDebugging ? segment() : "<private>"
                }
            }.joined()
        }

        init(literalCapacity: Int, interpolationCount: Int) {
            self.segments = [(() -> String, ApptentiveLogPrivacy)]()
        }

        mutating func appendLiteral(_ literal: String) {
            self.segments.append(({ literal }, .public))
        }

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> CustomDebugStringConvertible, privacy: ApptentiveLogPrivacy = .auto) {
            self.segments.append(
                (
                    {
                        argumentObject().debugDescription
                    }, privacy
                ))
        }

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> String, privacy: ApptentiveLogPrivacy = .auto) {
            self.segments.append((argumentObject, privacy))
        }

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> Error, privacy: ApptentiveLogPrivacy = .auto) {
            self.segments.append(
                (
                    {
                        argumentObject().localizedDescription
                    }, privacy
                ))
        }

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> Int, privacy: ApptentiveLogPrivacy = .auto) {
            self.segments.append(
                (
                    {
                        String(argumentObject())
                    }, privacy
                ))
        }
    }
}

/// Privacy levels that roughly correspond to the `OSLogPrivacy` class.
enum ApptentiveLogPrivacy {
    /// Choose the privacy level automatically (this is currently a synonym for `.private`).
    case auto

    /// Redact information marked as private unless a debugger is attached to the process.
    case `private`

    /// Do not redact the information.
    case `public`
}

extension ApptentiveLogger {
    private static let subsystemPrefix = (Bundle.main.bundleIdentifier ?? "com.apptentive") + ".apptentive"

    /// Logger for things that aren't really part of any other subsystem.
    static let `default` = ApptentiveLogger(subsystem: subsystemPrefix)

    /// Logger for engaging event and targeting.
    static let engagement = ApptentiveLogger(subsystem: subsystemPrefix + ".engagement")

    /// Logger for network-related activity.
    static let network = ApptentiveLogger(subsystem: subsystemPrefix + ".network")
}
