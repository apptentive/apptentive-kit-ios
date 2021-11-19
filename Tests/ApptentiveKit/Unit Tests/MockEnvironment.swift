//
//  MockEnvironment.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 9/10/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

@testable import ApptentiveKit

struct MockEnvironment: DeviceEnvironment, AppEnvironment, PlatformEnvironment {
    static let applicationSupportURL = URL(string: "file:///tmp/")!
    static let containerName = "com.apptentive.feedback"

    static func cleanContainerURL() throws {
        let containerURL = self.applicationSupportURL.appendingPathComponent(self.containerName)

        if FileManager.default.fileExists(atPath: containerURL.path) {
            try FileManager.default.removeItem(at: containerURL)
        }

        try FileManager.default.createDirectory(at: containerURL, withIntermediateDirectories: true, attributes: [:])
    }

    var identifierForVendor: UUID? = UUID(uuidString: "A230943F-14C7-4C57-BEA2-39EFC51F284C")
    var osName: String = "iOS"
    var osVersion: Version = "12.0"
    var localeIdentifier: String = "en_US"
    var localeRegionCode: String? = "US"
    var preferredLocalization: String? = "en"
    var timeZoneSecondsFromGMT: Int = -25200
    var appStoreReceiptURL: URL? = nil
    var carrier: String? = nil
    var osBuild: Version = "1"
    var hardware: String = "iPhone0,0"
    var contentSizeCategory = UIContentSizeCategory.medium
    var sdkVersion: Version = "0.0.0"
    var distributionName: String?
    var distributionVersion: Version?
    var isDebugBuild = true
    var isTesting = true
    var infoDictionary: [String: Any]? = [
        "CFBundleIdentifier": "com.apptentive.test",
        "CFBundleShortVersionString": "0.0.0",
        "CFBundleVersion": "1",
        "DTCompiler": "com.apple.compilers.llvm.clang.1_0",
        "DTPlatformBuild": "17E218",
        "DTPlatformName": "iphonesimulator",
        "DTPlatformVersion": "13.4",
        "DTSDKBuild": "17E218",
        "DTSDKName": "iphonesimulator13.4.internal",
        "DTXcode": "1160",
        "DTXcodeBuild": "11E703a",
        "MinimumOSVersion": "12.1",
    ]

    var fileManager = FileManager.default
    var isInForeground = true
    var isProtectedDataAvailable = true
    var delegate: EnvironmentDelegate?

    func applicationSupportURL() throws -> URL {
        return Self.applicationSupportURL
    }

    var shouldOpenURLSucceed = true
    func open(_ url: URL, completion: @escaping (Bool) -> Void) {
        completion(self.shouldOpenURLSucceed)
    }

    var shouldRequestReviewSucceed = true
    func requestReview(completion: @escaping (Bool) -> Void) {
        completion(shouldRequestReviewSucceed)
    }

    func startBackgroundTask() {}
    func endBackgroundTask() {}
}
