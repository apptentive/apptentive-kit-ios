//
//  ApptentiveV9ObjectsTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 8/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest
import UIKit

#if canImport(CoreTelephony)
import CoreTelephony
#endif

@testable import ApptentiveKit

class ApptentiveV9ObjectsTests: XCTestCase {
    func testConversationEncoding() throws {
        let conversation = Conversation(environment: MockEnvironment())
        let conversationRequest = ConversationRequest(conversation: conversation)

        let conversationRequestJSON = try JSONEncoder().encode(conversationRequest)

        let expectedJSONString = """
{
  "device": {
    "uuid": "A230943F-14C7-4C57-BEA2-39EFC51F284C",
    "os_name": "iOS",
    "locale_language_code": "en",
    "integration_config": {},
    "os_build": "1",
    "custom_data": {},
    "locale_country_code": "US",
    "utc_offset": -25200,
    "os_version": "12.0",
    "locale_raw": "en_US",
    "hardware": "iPhone0,0",
    "content_size_category": "UICTContentSizeCategoryM"
  },
  "appRelease": {
    "dt_platform_version": "13.4",
    "overriding_styles": false,
    "dt_xcode": "1160",
    "dt_xcode_build": "11E703a",
    "sdk_version": "0.0.0",
    "dt_sdk_name": "iphonesimulator13.4.internal",
    "type": "ios",
    "dt_sdk_build": "17E218",
    "dt_compiler": "com.apple.compilers.llvm.clang.1_0",
    "debug": true,
    "sdk_author_name": "Apptentive, Inc.",
    "dt_platform_build": "17E218",
    "sdk_platform": "Apple",
    "cf_bundle_identifier": "com.apptentive.test",
    "cf_bundle_short_version_string": "0.0.0",
    "app_store_receipt": false,
    "sdk_programming_language": "Swift",
    "cf_bundle_version": "1",
    "dt_platform_name": "iphonesimulator"
  },
  "person": {
    "custom_data": {}
  }
}
"""

        let expectedJSON = expectedJSONString.data(using: .utf8)!
        let decodedExpectedJSON = try JSONDecoder().decode(ConversationRequest.self, from: expectedJSON)
        let decodedConversationRequestJSON = try JSONDecoder().decode(ConversationRequest.self, from: conversationRequestJSON)

        XCTAssertEqual(decodedExpectedJSON.appRelease, decodedConversationRequestJSON.appRelease)
        XCTAssertEqual(decodedExpectedJSON.person, decodedConversationRequestJSON.person)
        XCTAssertEqual(decodedExpectedJSON.device, decodedConversationRequestJSON.device)
    }

    struct MockEnvironment: DeviceEnvironment, AppEnvironment {
        var identifierForVendor: UUID? = UUID(uuidString: "A230943F-14C7-4C57-BEA2-39EFC51F284C")
        var osName: String = "iOS"
        var osVersion: String = "12.0"
        var localeIdentifier: String = "en_US"
        var localeRegionCode: String? = "US"
        var preferredLocalization: String? = "en"
        var timeZoneSecondsFromGMT: Int = -25200
        var appStoreReceiptURL: URL? = nil
        var carrier: String? = nil
        var osBuild: String = "1"
        var hardware: String = "iPhone0,0"
        var contentSizeCategory = UIContentSizeCategory.medium
        var sdkVersion = "0.0.0"
        var distributionName: String?
        var distributionVersion: String?
        var isDebugBuild = true
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
            "DTXcodeBuild": "11E703a"
        ]
    }
}
