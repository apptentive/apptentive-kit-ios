//
//  DeviceTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 12/9/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class DeviceTests: XCTestCase {
    func testCustomData() {
        var device = Device(dataProvider: MockDataProvider())

        device.customData["string"] = "string"
        device.customData["number"] = 5
        device.customData["float"] = 1.1
        device.customData["boolean"] = true

        XCTAssertEqual(device.customData["string"] as? String, "string")
        XCTAssertEqual(device.customData["number"] as? Int, 5)
        XCTAssertEqual(device.customData["float"] as? Double, 1.1)
        XCTAssertEqual(device.customData["boolean"] as? Bool, true)
    }

    func testMerge() {
        let dataProvider = MockDataProvider()

        var device1 = Device(dataProvider: dataProvider)
        var device2 = Device(dataProvider: dataProvider)

        device1.customData["foo"] = "bar"
        device2.customData["foo"] = "baz"
        device2.customData["bar"] = "foo"

        device1.merge(with: device2)

        XCTAssertEqual(device1.customData["foo"] as? String, "baz")
        XCTAssertEqual(device1.customData["bar"] as? String, "foo")
    }

    func testPushToken() {
        var dataProvider = MockDataProvider()

        let tokenData = Data(hexString: "06e78d0d5604079bc0a642c19c26983d85a30b40613840501274087cd96415bf")!
        dataProvider.remoteNotificationDeviceToken = tokenData

        let device = Device(dataProvider: dataProvider)

        XCTAssertEqual(device.integrationConfiguration, ["apptentive_push": ["token": tokenData]])
    }
}
