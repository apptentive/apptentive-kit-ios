//
//  HTTPRequestRetrierTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct HTTPRequestRetrierTests {
    var requestRetrier: HTTPRequestRetrier!
    var requestor: SpyRequestor!
    let pendingCredentials = PendingAPICredentials(appCredentials: .init(key: "abc", signature: "123"))

    init() async {
        let responseString = """
            {
            "token": "abc123",
            "id": "def456",
            "person_id": "ghi789",
            "device_id": "jkl012"
            }
            """

        self.requestor = SpyRequestor(responseData: responseString.data(using: .utf8)!)
        await self.requestor.setResponseData("{\"token\": \"abc\", \"id\": \"123\", \"person_id\": \"def\"}".data(using: .utf8))
        await self.requestor.setResponse(HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 201, httpVersion: "1.1", headerFields: [:]))

        let client = HTTPClient(requestor: self.requestor, baseURL: URL(string: "https://www.example.com")!, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        self.requestRetrier = HTTPRequestRetrier()
        await self.requestRetrier.setClient(client)
    }

    @Test func testStart() async throws {
        let conversation = Conversation(dataProvider: MockDataProvider())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        let _: ConversationResponse = try await self.requestRetrier.start(builder, identifier: "create conversation")
    }

    @Test func testRetryOnConnectionError() async throws {
        let conversation = Conversation(dataProvider: MockDataProvider())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        await self.requestor.setError(.connectionError(FakeError()))
        await self.requestor.setExtraCompletion({ requestor in
            Task {
                if let _ = await requestor.error {
                    await requestor.setError(nil)
                }
            }
        })

        let _: ConversationResponse = try await self.requestRetrier.start(builder, identifier: "create conversation")
    }

    @Test func testNoRetryOnClientError() async {
        let conversation = Conversation(dataProvider: MockDataProvider())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)
        let errorResponse = HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 403, httpVersion: "1.1", headerFields: [:])!

        await self.requestor.setError(.clientError(errorResponse, nil))
        await self.requestor.setExtraCompletion({ requestor in
            Task {
                if let _ = await requestor.error {
                    await requestor.setError(nil)
                } else {
                    throw TestError(reason: "Should not retry request on client error")
                }
            }
        })

        await #expect(throws: HTTPClientError.self) {
            let _: ConversationResponse = try await self.requestRetrier.start(builder, identifier: "create conversation")
        }
    }

    @Test func testNoRetryOnUnauthorizedError() async throws {
        let conversation = Conversation(dataProvider: MockDataProvider())
        let builder = ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)

        let errorResponse = HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 401, httpVersion: "1.1", headerFields: [:])!

        await self.requestor.setResponseData("{\"error\":\"unauthorized\"}".data(using: .utf8))
        await self.requestor.setResponse(errorResponse)

        await #expect {
            let _: ConversationResponse = try await self.requestRetrier.start(builder, identifier: "create conversation")
        } throws: { error in
            guard case .unauthorized = error as? HTTPClientError else {
                return false
            }

            return true
        }
    }

    struct FakeError: Error {}
}
