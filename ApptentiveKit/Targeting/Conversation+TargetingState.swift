//
//  TargetingState.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 8/18/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

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

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }
    }
}

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

extension EngagementMetrics: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let key = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, field.position + 1)
        }

        let metric = self[key] ?? EngagementMetric()

        return try metric.value(for: field.nextComponent())
    }
}

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

        default:
            throw TargetingError.unrecognizedField(field.fullPath)
        }

    }
}

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

extension CustomData: TargetingState {
    func value(for field: Field) throws -> Any? {
        guard let key = field.keys.first else {
            throw TargetingError.unexpectedEndOfField(field.fullPath, field.position)
        }

        return self[key]
    }
}
