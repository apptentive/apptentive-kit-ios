//
//  ConversationRequestTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 8/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable import ApptentiveKit

#if canImport(CoreTelephony)
    import CoreTelephony
#endif

class ConversationRequestTests: XCTestCase {
    func testConversationEncoding() throws {
        let conversation = Conversation(dataProvider: MockDataProvider())
        let conversationRequest = ConversationRequest(conversation: conversation, token: nil)

        let conversationRequestJSON = try JSONEncoder.apptentive.encode(conversationRequest)

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
                "os_version": "13.0",
                "locale_raw": "en_US",
                "hardware": "iPhone0,0",
                "content_size_category": "UICTContentSizeCategoryM"
              },
              "app_release": {
                "dt_platform_version": "13.4",
                "overriding_styles": false,
                "deployment_target": "13.0",
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
                "sdk_platform": "iOS",
                "cf_bundle_identifier": "com.apptentive.test",
                "cf_bundle_short_version_string": "0.0.0",
                "app_store_receipt": {
                    "has_receipt": false
                },
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
        let decodedExpectedJSON = try JSONDecoder.apptentive.decode(ConversationRequest.self, from: expectedJSON)
        let decodedConversationRequestJSON = try JSONDecoder.apptentive.decode(ConversationRequest.self, from: conversationRequestJSON)

        XCTAssertEqual(decodedExpectedJSON.appRelease, decodedConversationRequestJSON.appRelease)
        XCTAssertEqual(decodedExpectedJSON.person, decodedConversationRequestJSON.person)
        XCTAssertEqual(decodedExpectedJSON.device, decodedConversationRequestJSON.device)
    }
}
