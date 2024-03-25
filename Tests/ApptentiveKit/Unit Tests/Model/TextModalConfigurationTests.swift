//
//  TextModalConfigurationTests.swift
//  ApptentiveFeatureTests
//
//  Created by Luqmaan Khan on 12/12/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

final class TextModalConfigurationTests: XCTestCase {

    func testDecoding() throws {
        let json = """
                 {
                    "title": "New Promotion!",
                    "body": "Redeem our exclusive promotion today and treat yourself to more discounts.",
                    "actions": [
                        {
                            "id": "action_id_1",
                            "label": "Redeem",
                            "action": "interaction",
                            "invokes": [
                                {
                                    "interaction_id": "54a3437b7724c57cf6000043",
                                    "criteria": {}
                                }
                            ]
                        },
                        {
                            "id": "action_id_2",
                            "label": "Dismiss",
                            "action": "dismiss"
                        }
                    ],
                    "image": {
                        "url": "https://variety.com/wp-content/uploads/2022/12/Disney-Plus.png",
                        "layout": "fill",
                        "alt_text": "Disney Logo"
                    },
                    "max_height": 40
                }
            """

        let data = json.data(using: .utf8)!

        let configuration = try JSONDecoder.apptentive.decode(TextModalConfiguration.self, from: data)
        XCTAssertEqual(configuration.title, "New Promotion!")
        XCTAssertEqual(configuration.body, "Redeem our exclusive promotion today and treat yourself to more discounts.")
        XCTAssertEqual(configuration.actions.count, 2)
        XCTAssertEqual(configuration.image?.url, URL(string: "https://variety.com/wp-content/uploads/2022/12/Disney-Plus.png")!)
        XCTAssertEqual(configuration.image?.layout, "fill")
        XCTAssertEqual(configuration.image?.altText, "Disney Logo")
    }

}
