//
//  ProvisioningProfileParser.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/27/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog

class ProvisioningProfileParser {
    static func getEntitlements() -> [String: Any]? {
        let mobileProvisionURL = Bundle.main.bundleURL.appendingPathComponent("embedded.mobileprovision")
        do {
            let data = try Data(contentsOf: mobileProvisionURL)

            return try self.getEntitlements(from: data)
        } catch (let error) {
            ApptentiveLogger.default.info("Unable to read provisioning profile: \(error)")
            return nil
        }
    }

    static func getEntitlements(from profileData: Data) throws -> [String: Any]? {
        do {
            let provisioningPlist = try ProvisioningProfileParser.parse(profileData: profileData)

            return provisioningPlist["Entitlements"] as? [String: Any] ?? [:]
        } catch (let error) {
            ApptentiveLogger.default.info("Unable to parse provisioning profile: \(error)")
            return nil
        }
    }

    static func parse(profileData: Data) throws -> [String: Any] {
        guard let startMarker = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".data(using: .utf8),
            let endMarker = "</plist>".data(using: .utf8),
            let startRange = profileData.range(of: startMarker),
            let endRange = profileData.range(of: endMarker)
        else {
            throw ApptentiveError.internalInconsistency
        }

        let plistData = profileData.subdata(in: startRange.lowerBound..<endRange.upperBound)
        let plistObject = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)

        guard let plistDictionary = plistObject as? [String: Any] else {
            throw ApptentiveError.internalInconsistency
        }

        return plistDictionary
    }
}
