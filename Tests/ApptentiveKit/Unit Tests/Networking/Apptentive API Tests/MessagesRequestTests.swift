//
//  MessagesRequestTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 1/7/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct MessagesRequestTests {
    @Test func testMessagesResponseDecoding() throws {
        let responseJSON: String = """
            {"messages":[{"client_created_at":1641583420.3243,"client_created_at_utc_offset":-28800,"custom_data":null,"id":"61d8933c1c677477270b0f2e","nonce":"0E5F6F97-24B3-4E9E-AE36-70C428F3DD04","inbound":true,"attachments":[],"created_at":1641583420.4529998,"sender":{"id":"61d893341c677476ee0ac9dd","name":null,"profile_photo":"https://secure.gravatar.com/avatar/d41d8cd98f00b204e9800998ecf8427e.png"},"body":"Hey"}],"ends_with":"61d8933c1c677477270b0f2e","has_more":false}
            """

        let responseData = responseJSON.data(using: .utf8)!

        let response = try JSONDecoder.apptentive.decode(MessagesResponse.self, from: responseData)

        #expect(response.messages.count == 1)
    }
}
