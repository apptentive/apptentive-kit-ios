//
//  ConfigurationTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 10/6/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class ConfigurationTests: XCTestCase {
    func testDecoding() throws {
        let json = """
            {"support_display_name":"Casey Test","support_display_email":"casey@apptentive.com","hide_branding":false,"message_center":{"title":"Message Center","fg_poll":10,"bg_poll":300,"email_required":true,"notification_popup":{"enabled":false}},"support_image_url":"https://secure.gravatar.com/avatar/b894bf8f0a54da9e36f2b1c490da28a3","message_center_enabled":true,"metrics_enabled":true,"apptimize_integration":true,"collect_ad_id":false}
            """

        let data = json.data(using: .utf8)!

        let configuration = try JSONDecoder.apptentive.decode(Configuration.self, from: data)

        XCTAssertEqual(configuration.supportName, "Casey Test")
        XCTAssertEqual(configuration.supportEmail, "casey@apptentive.com")
        XCTAssertEqual(configuration.hideBranding, false)
        XCTAssertEqual(configuration.supportImageURL, URL(string: "https://secure.gravatar.com/avatar/b894bf8f0a54da9e36f2b1c490da28a3"))
        XCTAssertEqual(configuration.enableMessageCenter, true)
        XCTAssertEqual(configuration.enableMetrics, true)
        XCTAssertEqual(configuration.useApptimizeIntegration, true)
        XCTAssertEqual(configuration.collectAdvertisingID, false)

        XCTAssertEqual(configuration.messageCenter.title, "Message Center")
        XCTAssertEqual(configuration.messageCenter.foregroundPollingInterval, 10)
        XCTAssertEqual(configuration.messageCenter.backgroundPollingInterval, 300)
        XCTAssertEqual(configuration.messageCenter.requireEmail, true)

        XCTAssertEqual(configuration.messageCenter.notificationPopup.isEnabled, false)
    }
}
