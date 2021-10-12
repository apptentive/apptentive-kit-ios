//
//  AppReleasePayloadTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/4/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class AppReleasePayloadTests: XCTestCase {
    func testAppReleaseEncoding() throws {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.dateEncodingStrategy = .secondsSince1970

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .secondsSince1970

        let environment = MockEnvironment()

        let appRelease = AppRelease(environment: environment)

        let appReleasePayload = Payload(wrapping: appRelease)

        let encodedAppReleasePayload = try jsonEncoder.encode(appReleasePayload)

        let expectedJSONString = """
                        {
                          "app_release": {
                            "sdk_version": "0.0.0",
                            "dt_platform_version": "13.4",
                            "dt_platform_build": "17E218",
                            "cf_bundle_short_version_string": "0.0.0",
                            "sdk_platform": "Apple",
                            "client_created_at_utc_offset": -28800,
                            "cf_bundle_version": "1",
                            "app_store_receipt": {
                              "has_receipt": false
                            },
                            "sdk_programming_language": "Swift",
                            "client_created_at": 1600904569,
                            "dt_xcode_build": "11E703a",
                            "dt_xcode": "1160",
                            "nonce": "3EED102B-E0CA-4E8F-BAAA-8BBF9BD3C534",
                            "type": "ios",
                            "dt_platform_name": "iphonesimulator",
                            "overriding_styles": false,
                            "dt_sdk_name": "iphonesimulator13.4.internal",
                            "debug": true,
                            "sdk_author_name": "Apptentive, Inc.",
                            "dt_compiler": "com.apple.compilers.llvm.clang.1_0",
                            "dt_sdk_build": "17E218",
                            "sdk_distribution": null,
                            "sdk_distribution_version": null,
                            "cf_bundle_identifier": "com.apptentive.test"
                          }
                        }
            """

        let encodedExpectedJSON = expectedJSONString.data(using: .utf8)!

        let decodedExpectedJSON = try jsonDecoder.decode(Payload.self, from: encodedExpectedJSON)
        let decodedAppReleasePayloadJSON = try jsonDecoder.decode(Payload.self, from: encodedAppReleasePayload)

        XCTAssertNotNil(decodedAppReleasePayloadJSON.nonce)
        XCTAssertNotNil(decodedAppReleasePayloadJSON.creationDate)
        XCTAssertNotNil(decodedAppReleasePayloadJSON.creationUTCOffset)

        XCTAssertEqual(decodedExpectedJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))
        XCTAssertGreaterThan(decodedAppReleasePayloadJSON.creationDate, Date(timeIntervalSince1970: 1_600_904_569))

        guard case let PayloadContents.appRelease(payload) = decodedAppReleasePayloadJSON.contents else {
            return XCTFail("Not an appRelease payload")
        }

        XCTAssertEqual(payload.bundleIdentifier, environment.infoDictionary?["CFBundleIdentifier"] as? String)
        XCTAssertEqual(payload.version, environment.infoDictionary?["CFBundleShortVersionString"] as? String)
        XCTAssertEqual(payload.build, environment.infoDictionary?["CFBundleVersion"] as? String)
        XCTAssertEqual(payload.compiler, environment.infoDictionary?["DTCompiler"] as? String)
        XCTAssertEqual(payload.platformBuild, environment.infoDictionary?["DTPlatformBuild"] as? String)
        XCTAssertEqual(payload.platformName, environment.infoDictionary?["DTPlatformName"] as? String)
        XCTAssertEqual(payload.platformVersion, environment.infoDictionary?["DTPlatformVersion"] as? String)
        XCTAssertEqual(payload.sdkBuild, environment.infoDictionary?["DTSDKBuild"] as? String)
        XCTAssertEqual(payload.sdkName, environment.infoDictionary?["DTSDKName"] as? String)
        XCTAssertEqual(payload.xcode, environment.infoDictionary?["DTXcode"] as? String)
        XCTAssertEqual(payload.xcodeBuild, environment.infoDictionary?["DTXcodeBuild"] as? String)
        XCTAssertEqual(payload.appStoreReceipt.hasReceipt, environment.appStoreReceiptURL != nil)
        XCTAssertEqual(payload.isDebugBuild, environment.isDebugBuild)
        XCTAssertEqual(payload.sdkVersion, environment.sdkVersion.versionString)
        XCTAssertEqual(payload.sdkProgrammingLanguage, "Swift")
        XCTAssertEqual(payload.sdkAuthorName, "Apptentive, Inc.")
        XCTAssertEqual(payload.sdkPlatform, "iOS")
        XCTAssertEqual(payload.sdkDistributionName, environment.distributionName)
        XCTAssertEqual(payload.sdkDistributionVersion, environment.distributionVersion?.versionString)
    }
}
