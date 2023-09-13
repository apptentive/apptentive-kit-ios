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
public struct ApptentiveLogger {
    private let log: OSLog?

    /// Whether potentially-sensitve portions of log messages should be redacted.
    ///
    /// Defaults to `false` if the SDK detects that a debugger is attached, `true` otherwise.
    public static var shouldHideSensitiveLogs: Bool = !Self.isDebugging

    static let isDebugging: Bool = {
        isatty(STDERR_FILENO) != 0
    }()

    /// Creates a logger with the specified subsystem.
    init(subsystem: String) {
        if #available(iOS 12.0, *) {
            self.log = OSLog(subsystem: subsystem, category: "Apptentive")
        } else {
            self.log = nil
        }
    }

    private func log(_ message: ApptentiveLogMessage, level: LogLevel) {
        if level >= self.logLevel {
            if #available(iOS 12.0, *) {
                guard let log = self.log else {
                    apptentiveCriticalError("Expected log to be available in iOS 12+")
                    return
                }

                os_log(level.logType, log: log, "%{public}@", message.description)
            } else {
                print("\(level.label)/Apptentive: \(message.description)")
            }
        }
    }

    /// Logs a debug message.
    /// - Parameter message: The message to log.
    func debug(_ message: ApptentiveLogMessage) {
        self.log(message, level: .debug)
    }

    /// Log an info message.
    /// - Parameter message: The message to log.
    func info(_ message: ApptentiveLogMessage) {
        self.log(message, level: .info)
    }

    /// Log a message at the default level.
    /// - Parameter message: The message to log.
    func notice(_ message: ApptentiveLogMessage) {
        self.log(message, level: .notice)
    }

    /// Log a message at the error level.
    ///
    /// Provided for compatability with the `Logger` class.
    /// - Parameter message: The message to log.
    func warning(_ message: ApptentiveLogMessage) {
        self.log(message, level: .warning)
    }

    /// Log a message at the error level.
    /// - Parameter message: The message to log.
    func error(_ message: ApptentiveLogMessage) {
        self.log(message, level: .error)
    }

    /// Log a message at the fault level.
    ///
    /// Provided for compatability with the `Logger` class.
    /// - Parameter message: The message to log.
    func critcal(_ message: ApptentiveLogMessage) {
        self.log(message, level: .critical)
    }

    /// Log a message at the fault level.
    /// - Parameter message: The message to log.
    func fault(_ message: ApptentiveLogMessage) {
        self.log(message, level: .fault)
    }

    /// Sets the log level for the log.
    ///
    /// Log messages at a level below this value will be silenced.
    public var logLevel: LogLevel = .notice
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
            return self.segments.map { (segment, privacy) in
                switch privacy {
                case .public:
                    return segment()
                case .private:
                    return !ApptentiveLogger.isDebugging ? "<private>" : segment()
                case .auto:
                    return ApptentiveLogger.shouldHideSensitiveLogs ? "<private>" : segment()
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

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> Error, privacy: ApptentiveLogPrivacy = .public) {
            self.segments.append(
                (
                    {
                        argumentObject().localizedDescription
                    }, privacy
                ))
        }

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> URL, privacy: ApptentiveLogPrivacy = .public) {
            self.segments.append(
                (
                    {
                        argumentObject().absoluteString
                    }, privacy
                ))
        }

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> Int, privacy: ApptentiveLogPrivacy = .public) {
            self.segments.append(
                (
                    {
                        String(argumentObject())
                    }, privacy
                ))
        }

        mutating func appendInterpolation(_ argumentObject: @autoclosure @escaping () -> Bool, privacy: ApptentiveLogPrivacy = .public) {
            self.segments.append(
                (
                    {
                        argumentObject() ? "true" : "false"
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
    public static var `default` = ApptentiveLogger(subsystem: subsystemPrefix)

    /// Logger for engaging event and targeting.
    public static var engagement = ApptentiveLogger(subsystem: subsystemPrefix + ".engagement")

    /// Logger for interaction-related activity.
    public static var interaction = ApptentiveLogger(subsystem: subsystemPrefix + ".interaction")

    /// Logger for network-related activity.
    public static var network = ApptentiveLogger(subsystem: subsystemPrefix + ".network")

    /// Logger for payload sender activity.
    public static var payload = ApptentiveLogger(subsystem: subsystemPrefix + ".payload")

    /// Logger for targeting activity.
    public static var targeting = ApptentiveLogger(subsystem: subsystemPrefix + ".targeting")

    /// Logger for message center messages.
    public static var messages = ApptentiveLogger(subsystem: subsystemPrefix + ".messages")

    /// Logger for message center attachments.
    public static var attachments = ApptentiveLogger(subsystem: subsystemPrefix + ".attachments")

    /// The overall log level.
    ///
    /// Reading this value returns the log level of the default log.
    /// Setting this value sets the log level for all logs.
    public static var logLevel: LogLevel {
        get {
            return self.default.logLevel
        }
        set {
            self.default.logLevel = newValue
            self.engagement.logLevel = newValue
            self.interaction.logLevel = newValue
            self.network.logLevel = newValue
            self.payload.logLevel = newValue
            self.targeting.logLevel = newValue
            self.attachments.logLevel = newValue
            self.messages.logLevel = newValue
        }
    }
}

/// The log levels.
public enum LogLevel: Int, Comparable {
    case debug
    case info
    case notice
    case warning
    case error
    case critical
    case fault

    var logType: OSLogType {
        switch self {
        case .debug:
            return .debug

        case .info:
            return .info

        case .notice:
            return .default

        case .warning, .error:
            return .error

        case .critical, .fault:
            return .fault
        }
    }

    // swift-format-ignore
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .debug:
            return "D"

        case .info:
            return "I"

        case .notice:
            return "N"

        case .warning:
            return "W"

        case .error:
            return "E"

        case .critical:
            return "C"

        case .fault:
            return "F"
        }
    }
}
