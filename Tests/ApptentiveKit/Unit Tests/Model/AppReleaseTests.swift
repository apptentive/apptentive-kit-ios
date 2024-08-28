//
//  AppReleaseTests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 12/9/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class AppReleaseTests: XCTestCase {

    func testMerge() {
        let dataProvider = MockDataProvider()

        var appRelease1 = AppRelease(dataProvider: dataProvider)
        var appRelease2 = AppRelease(dataProvider: dataProvider)

        appRelease2.version = "1"

        XCTAssertFalse(appRelease1.isUpdatedVersion)
        XCTAssertFalse(appRelease1.isUpdatedBuild)

        let newerVersion: Version = "2"
        appRelease2.sdkDistributionVersion = newerVersion

        appRelease1.merge(with: appRelease2)

        XCTAssertTrue(appRelease1.isUpdatedVersion)
        XCTAssertEqual(appRelease1.sdkDistributionVersion, newerVersion)

        appRelease2.build = "2"

        appRelease1.merge(with: appRelease2)

        XCTAssertTrue(appRelease1.isUpdatedBuild)
    }
}
