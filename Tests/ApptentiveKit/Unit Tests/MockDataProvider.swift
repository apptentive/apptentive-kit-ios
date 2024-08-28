//
//  MockDataProvider.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/30/24.
//  Copyright © 2024 Apptentive, Inc. All rights reserved.
//

import UIKit

@testable import ApptentiveKit

struct MockDataProvider: ConversationDataProviding {
    var bundleIdentifier: String? = "com.apptentive.test"
    var version: ApptentiveKit.Version? = "0.0.0"
    var build: ApptentiveKit.Version? = "1"
    var deploymentTarget: String? = "13.0"
    var compiler: String? = "com.apple.compilers.llvm.clang.1_0"
    var platformBuild: String? = "17E218"
    var platformName: String? = "iphonesimulator"
    var platformVersion: String? = "13.4"
    var sdkBuild: String? = "17E218"
    var sdkName: String? = "iphonesimulator13.4.internal"
    var xcode: String? = "1160"
    var xcodeBuild: String? = "11E703a"
    var isOverridingStyles: Bool = false
    var identifierForVendor: UUID? = UUID(uuidString: "A230943F-14C7-4C57-BEA2-39EFC51F284C")
    var osName: String = "iOS"
    var osVersion: Version = "13.0"
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
    var remoteNotificationDeviceToken: Data?
}
