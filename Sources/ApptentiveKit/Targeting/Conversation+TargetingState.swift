//
//  Conversation+TargetingState.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Adds the ability to query the conversation for the values of fields.
extension Conversation: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let firstKey = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, 0)
        }

        switch firstKey {
        case "current_time":
            return Date()

        case "application", "sdk", "is_update", "time_at_install":
            return try self.appRelease.value(for: try field.nextComponent())

        case "code_point":
            return try self.codePoints.value(for: try field.nextComponent())

        case "interactions":
            return try self.interactions.value(for: try field.nextComponent())

        case "person":
            return try self.person.value(for: try field.nextComponent())

        case "device":
            return try self.device.value(for: try field.nextComponent())

        case "random":
            return try self.random.value(for: try field.nextComponent())

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }
    }
}

/// Adds the ability to query the app release for the values of fields.
extension AppRelease: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let firstKey = field.keys.first, let previousKey = field.parentKeys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, 0)
        }

        switch (previousKey, firstKey) {
        case ("application", "cf_bundle_short_version_string"):
            return self.version

        case ("application", "cf_bundle_version"):
            return self.build

        case ("application", "debug"):
            return self.isDebugBuild

        case ("sdk", "version"):
            return self.sdkVersion

        case ("is_update", "cf_bundle_short_version_string"):
            return self.isUpdatedVersion

        case ("is_update", "cf_bundle_version"):
            return self.isUpdatedBuild

        case ("time_at_install", "total"):
            return self.installTime

        case ("time_at_install", "cf_bundle_short_version_string"):
            return self.versionInstallTime

        case ("time_at_install", "cf_bundle_version"):
            return self.buildInstallTime

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }
    }
}

/// Adds the ability to query the engagement metrics for the values of fields.
extension EngagementMetrics: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let key = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, field.position + 1)
        }

        let metric = self[key] ?? EngagementMetric()

        return try metric.value(for: field.nextComponent())
    }
}

/// Adds the ability to query an engagement metric for the values of fields.
extension EngagementMetric: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let firstKey = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, 0)
        }

        switch firstKey {
        case "last_invoked_at":
            return self.lastInvoked

        case "invokes":
            let subfield = try field.nextComponent()

            switch subfield.keys.first {
            case "total":
                return self.totalCount

            case "cf_bundle_short_version_string":
                return self.versionCount

            case "cf_bundle_version":
                return self.buildCount

            default:
                throw TargetingError.unrecognizedField(subfield.fullPath)
            }

        case "answers":
            let subfield = try field.nextComponent()

            switch subfield.keys.first {
            case "value":
                let result = Set(self.answers.compactMap { $0.value })
                return result.count > 0 ? result : nil

            case "id":
                let result = Set(self.answers.compactMap { $0.id })
                return result.count > 0 ? result : nil

            default:
                throw TargetingError.unrecognizedField(field.fullPath)
            }

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }

    }
}

/// Adds the ability to query the device for the values of fields.
extension Device: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let firstKey = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, 0)
        }

        switch firstKey {
        case "uuid":
            return self.uuid

        case "os_name":
            return self.osName

        case "os_version":
            return self.osVersion

        case "os_build":
            return self.osBuild

        case "hardware":
            return self.hardware

        case "carrier":
            return self.carrier

        case "content_size_category":
            return self.contentSizeCategory

        case "locale_raw":
            return self.localeRaw

        case "locale_country_code":
            return self.localeCountryCode

        case "locale_language_code":
            return self.localeLanguageCode

        case "custom_data":
            return try self.customData.value(for: try field.nextComponent())

        case "utc_offset":
            return self.utcOffset

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }
    }
}

/// Adds the ability to query the person for the values of fields.
extension Person: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let firstKey = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, 0)
        }

        switch firstKey {
        case "name":
            return self.name

        case "email":
            return self.emailAddress

        case "custom_data":
            return try self.customData.value(for: try field.nextComponent())

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }
    }
}

/// Adds the ability to query the custom data for the values of fields.
extension CustomData: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let key = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, field.position)
        }

        return self[key]
    }
}

/// Adds the ability to query the random sample values for the values of fields.
extension Random: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard field.keys.count <= 2 else {
            throw TargetingError.unrecognizedField(field.fullPath)
        }

        guard let firstKey = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, field.position)
        }

        let nextKey = field.keys.count > 1 ? field.keys[1] : nil

        switch (firstKey, nextKey) {
        case (let key, "percent"):
            return self.randomPercent(for: key)

        case ("percent", nil):
            return self.newRandomPercent()

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }
    }
}

/// Adds the ability to query the interaction response for the values of fields.
extension Answer {
    var id: String? {
        switch self {

        case .choice(let id):
            return id

        case .other(let id, _):
            return id

        default:
            return nil
        }
    }

    var value: Value? {
        switch self {
        case .freeform(let value):
            return .string(value)

        case .range(let value):
            return .int(value)

        case .other(_, let value):
            return .string(value)

        default:
            return nil
        }
    }

    enum Value: Equatable, Hashable {
        case int(Int)
        case string(String)

        var intValue: Int? {
            if case .int(let int) = self {
                return int
            } else {
                return nil
            }
        }

        var stringValue: String? {
            if case .string(let string) = self {
                return string
            } else {
                return nil
            }
        }
    }
}
