//
//  TextModalConfigurationTests.swift
//  ApptentiveFeatureTests
//
//  Created by Luqmaan Khan on 12/12/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct TextModalConfigurationTests {
    @Test func testDecoding() throws {
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
        #expect(configuration.title.flatMap { String($0.characters) } == "New Promotion!")
        #expect(configuration.body.flatMap { String($0.characters) } == "Redeem our exclusive promotion today and treat yourself to more discounts.")
        #expect(configuration.actions.count == 2)
        #expect(configuration.image?.url == URL(string: "https://variety.com/wp-content/uploads/2022/12/Disney-Plus.png")!)
        #expect(configuration.image?.layout == "fill")
        #expect(configuration.image?.altText == "Disney Logo")
    }

}
