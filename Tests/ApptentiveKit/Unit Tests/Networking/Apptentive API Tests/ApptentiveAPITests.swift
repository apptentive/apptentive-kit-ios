//
//  ApptentiveAPITests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

class ApptentiveAPITests: XCTestCase {
    var payloadContext: Payload.Context!
    var pendingCredentials = PendingAPICredentials(appCredentials: .init(key: "abc", signature: "123"))
    var anonymousCredentials = AnonymousAPICredentials(appCredentials: .init(key: "abc", signature: "123"), conversationCredentials: .init(id: "def", token: "456"))

    override func setUpWithError() throws {
        self.payloadContext = Payload.Context(
            tag: ".", credentials: .header(id: anonymousCredentials.conversationCredentials.id, token: anonymousCredentials.conversationCredentials.token), sessionID: "abc123", encoder: JSONEncoder.apptentive, encryptionContext: nil)
    }

    class MockAppCredentialsProvider: PayloadAuthenticationDelegate {
        var appCredentials: Apptentive.AppCredentials? {
            return .init(key: "abc", signature: "123")
        }

        func authenticationDidFail(with errorResponse: ErrorResponse?) {}
    }

    func testBuildHeaders() {
        let headers = ApptentiveAPI.buildHeaders(
            credentials: self.anonymousCredentials,
            contentType: "foo/bar",
            accept: "foo/bar",
            acceptCharset: "utf-123",
            acceptLanguage: "de",
            userAgent: "Apptentive/1.2.3 (Apple)",
            apiVersion: "9"
        )

        let expectedHeaders = [
            "APPTENTIVE-KEY": "abc",
            "APPTENTIVE-SIGNATURE": "123",
            "X-API-Version": "9",
            "Content-Type": "foo/bar",
            "Authorization": "Bearer 456",
            "Accept": "foo/bar",
            "Accept-Charset": "utf-123",
            "Accept-Language": "de",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
        ]

        XCTAssertEqual(headers, expectedHeaders)
    }

    func testBuildRequest() throws {
        let path = "foo"
        let method = HTTPMethod.delete
        let bodyObject = MockHTTPBodyPart(foo: "foo", bar: "bar")
        let baseURL = URL(string: "https://api.example.com/")!

        let endpoint = ApptentiveAPI(credentials: self.anonymousCredentials, path: path, method: method, bodyObject: bodyObject)

        let request = try endpoint.buildRequest(baseURL: baseURL, userAgent: "Apptentive/1.2.3 (Apple)", languageCode: "de")

        let expectedHeaders = [
            "APPTENTIVE-KEY": "abc",
            "APPTENTIVE-SIGNATURE": "123",
            "X-API-Version": "14",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "application/json;charset=UTF-8",
            "Authorization": "Bearer 456",
            "Accept": "application/json;charset=UTF-8",
            "Accept-Charset": "UTF-8",
            "Accept-Language": "de",
        ]

        XCTAssertEqual(request.url, URL(string: "https://api.example.com/conversations/def/foo")!)
        XCTAssertEqual(request.httpMethod, method.rawValue)
        XCTAssertEqual(request.allHTTPHeaderFields, expectedHeaders)
    }

    func testBuildMultipartRequest() throws {
        let path = "foo"
        let method = HTTPMethod.delete
        let bodyObject = MockHTTPBodyPart(foo: "foo", bar: "bar")
        let baseURL = URL(string: "https://api.example.com/")!

        let part1 = bodyObject

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let data1 = image1.pngData()!
        let part2 = Payload.Attachment(contentType: "image/png", filename: "logo", contents: .data(data1))

        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let data2 = image2.jpegData(compressionQuality: 0.5)!
        let part3 = Payload.Attachment(contentType: "image/jpeg", filename: "dog", contents: .data(data2))

        let endpoint = ApptentiveAPI(credentials: self.anonymousCredentials, path: path, method: method, bodyParts: [part1, part2, part3])

        let request = try endpoint.buildRequest(baseURL: baseURL, userAgent: "Apptentive/1.2.3 (Apple)", languageCode: "de")

        let expectedHeaders = [
            "APPTENTIVE-KEY": "abc",
            "APPTENTIVE-SIGNATURE": "123",
            "X-API-Version": "14",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "multipart/mixed; boundary=\(endpoint.boundaryString)",
            "Authorization": "Bearer 456",
            "Accept": "application/json;charset=UTF-8",
            "Accept-Charset": "UTF-8",
            "Accept-Language": "de",
        ]

        XCTAssertEqual(request.url, URL(string: "https://api.example.com/conversations/def/foo")!)
        XCTAssertEqual(request.httpMethod, method.rawValue)
        XCTAssertEqual(request.allHTTPHeaderFields, expectedHeaders)

        let parts = try Self.parseMultipartBody(request.httpBody!, boundary: endpoint.boundaryString)

        XCTAssertEqual(parts.count, 3)

        let expectedPartHeaders = [
            [
                "Content-Type": "application/json;charset=UTF-8",
                "Content-Disposition": "form-data; name=\"data\"",
            ],
            [
                "Content-Type": "image/png",
                "Content-Disposition": "form-data; name=\"file[]\"; filename=\"logo\"",
            ],
            [
                "Content-Type": "image/jpeg",
                "Content-Disposition": "form-data; name=\"file[]\"; filename=\"dog\"",
            ],
        ]

        XCTAssertEqual(parts[0].headers, expectedPartHeaders[0])
        XCTAssertEqual(parts[1].headers, expectedPartHeaders[1])
        XCTAssertEqual(parts[2].headers, expectedPartHeaders[2])

        let decodedBodyObject = try JSONDecoder.apptentive.decode(MockHTTPBodyPart.self, from: parts[0].content)
        XCTAssertEqual(bodyObject, decodedBodyObject)
        XCTAssertEqual(parts[1].content, data1)
        XCTAssertEqual(parts[2].content, data2)
    }

    func testBuildUserAgent() {
        let userAgent = ApptentiveAPI.userAgent(sdkVersion: "1.2.3")

        XCTAssertEqual(userAgent, "Apptentive/1.2.3 (Apple)")
    }

    func testParseExpiry() {
        let response1 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Cache-Control": "max-age = 86400"])!

        guard let expiry1 = ApptentiveAPI.parseExpiry(response1) else {
            return XCTFail("Unable to parse valid expiry")
        }

        XCTAssertEqual(expiry1.timeIntervalSinceNow, Date(timeIntervalSinceNow: 86400).timeIntervalSinceNow, accuracy: 1.0)

        let response2 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Cache-control": "axmay-agehay: 86400"])!

        let expiry2 = ApptentiveAPI.parseExpiry(response2)

        XCTAssertNil(expiry2)

        XCTAssertEqual(expiry1.timeIntervalSinceNow, Date(timeIntervalSinceNow: 86400).timeIntervalSinceNow, accuracy: 1.0)

        let response3 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["cAcHe-cOnTrOl": "max-age = 650"])!

        guard let expiry3 = ApptentiveAPI.parseExpiry(response3) else {
            return XCTFail("Unable to parse valid expiry (with weird case)")
        }

        XCTAssertEqual(expiry3.timeIntervalSinceNow, Date(timeIntervalSinceNow: 650).timeIntervalSinceNow, accuracy: 1.0)
    }

    func testCreateConversation() throws {
        let baseURL = URL(string: "http://example.com")!
        let conversation = Conversation(environment: MockEnvironment())
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))

        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")

        let expectation = XCTestExpectation()

        let _ = client.request(ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil)) { (result: Result<ConversationResponse, Error>) in
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Error (fake) creating conversation: \(error)")
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testCreateSurveyResponse() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        payloadSender.authenticationDelegate = appCredentialsProvider

        let surveyResponse = SurveyResponse(surveyID: "789", questionResponses: ["1": .answered([Answer.freeform("foo")])])

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/surveys/789/responses"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            expectation.fulfill()
        }

        try payloadSender.send(Payload(wrapping: surveyResponse, with: self.payloadContext))

        self.wait(for: [expectation], timeout: 5)
    }

    func testCreateEvent() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        payloadSender.authenticationDelegate = appCredentialsProvider

        let event = Event(name: "Foobar")

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/events"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            expectation.fulfill()
        }

        try payloadSender.send(Payload(wrapping: event, with: self.payloadContext))

        self.wait(for: [expectation], timeout: 5)
    }

    func testUpdatePerson() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        payloadSender.authenticationDelegate = appCredentialsProvider

        var customData = CustomData()
        customData["foo"] = "bar"
        customData["number"] = 2
        customData["bool"] = false

        let person = Person(name: "Testy McTestface", emailAddress: "test@example.com", mParticleID: nil, customData: customData)

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/person"))
            XCTAssertEqual(requestor.request?.httpMethod, "PUT")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            expectation.fulfill()
        }

        try payloadSender.send(Payload(wrapping: person, with: self.payloadContext))

        self.wait(for: [expectation], timeout: 5)
    }

    func testUpdateDevice() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        payloadSender.authenticationDelegate = appCredentialsProvider

        var customData = CustomData()
        customData["foo"] = "bar"
        customData["number"] = 2
        customData["bool"] = false

        var device = Device(environment: MockEnvironment())
        device.customData = customData

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/device"))
            XCTAssertEqual(requestor.request?.httpMethod, "PUT")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            expectation.fulfill()
        }

        try payloadSender.send(Payload(wrapping: device, with: self.payloadContext))

        self.wait(for: [expectation], timeout: 5)
    }

    func testUpdateAppRelease() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        payloadSender.authenticationDelegate = appCredentialsProvider

        let appRelease = AppRelease(environment: MockEnvironment())

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/app_release"))
            XCTAssertEqual(requestor.request?.httpMethod, "PUT")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            expectation.fulfill()
        }

        try payloadSender.send(Payload(wrapping: appRelease, with: self.payloadContext))

        self.wait(for: [expectation], timeout: 5)
    }

    func testCreateMessage() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let retryPolicy = HTTPRetryPolicy(initialDelay: 0, multiplier: 0, useJitter: false)
        let requestRetrier = HTTPRequestRetrier(retryPolicy: retryPolicy, client: client, queue: DispatchQueue.main)
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        payloadSender.authenticationDelegate = appCredentialsProvider

        var customData = CustomData()
        customData["foo"] = "bar"
        customData["number"] = 2
        customData["bool"] = false

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: type(of: self)), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: type(of: self)), compatibleWith: nil)!

        let data1 = image1.pngData()!
        let data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = MessageList.Message.Attachment(contentType: "image/png", filename: "apptentive-logo", storage: .inMemory(data1))
        let attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "dog", storage: .inMemory(data2))

        let message = MessageList.Message(nonce: "draft", body: "Test Message", attachments: [attachment1, attachment2], status: .draft)

        let expectation = XCTestExpectation()

        requestor.extraCompletion = {
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/messages"))
            XCTAssertEqual(requestor.request?.httpMethod, "POST")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            // get boundary from content type `multipart/mixed; boundary=<boundary>`
            guard let contentType = requestor.request?.allHTTPHeaderFields?["Content-Type"],
                let boundaryAttribute = contentType.components(separatedBy: "; ").last,
                let boundary = boundaryAttribute.components(separatedBy: "=").last
            else {
                return XCTFail("Unable to get boundary from Content-Type header.")
            }

            guard let body = requestor.request?.httpBody else {
                return XCTFail("No multipart body.")
            }

            do {
                let parts = try Self.parseMultipartBody(body, boundary: boundary)

                XCTAssertEqual(parts[0].headers["Content-Type"], "application/json;charset=UTF-8")
                XCTAssertEqual(parts[0].headers["Content-Disposition"], "form-data; name=\"message\"")
                let message = try JSONDecoder.apptentive.decode(Payload.JSONObject.self, from: parts[0].content)

                guard case Payload.SpecializedJSONObject.message(let messageContent) = message.specializedJSONObject else {
                    return XCTFail("Message payload doesn't contain message stuff")
                }

                XCTAssertEqual(messageContent.body, "Test Message")

                XCTAssertEqual(parts[1].headers["Content-Type"], "image/png")
                XCTAssertEqual(parts[1].headers["Content-Disposition"], "form-data; name=\"file[]\"; filename=\"apptentive-logo\"")
                XCTAssertEqual(parts[1].content, data1)

                XCTAssertEqual(parts[2].headers["Content-Type"], "image/jpeg")
                XCTAssertEqual(parts[2].headers["Content-Disposition"], "form-data; name=\"file[]\"; filename=\"dog\"")
                XCTAssertEqual(parts[2].content, data2)

                expectation.fulfill()
            } catch let error {
                XCTFail("Error decoding multipart body: \(error).")
            }
        }

        let payload = try Payload(wrapping: message, with: self.payloadContext, customData: nil, attachmentURLProvider: MockAttachmentURLProviding())
        payloadSender.send(payload)

        self.wait(for: [expectation], timeout: 5)
    }

    func testGetInteractions() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")

        let expectation = XCTestExpectation()
        let _ = client.request(ApptentiveAPI.getInteractions(with: self.anonymousCredentials)) { (result: Result<ConversationResponse, Error>) in
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/interactions"))
            XCTAssertEqual(requestor.request?.httpMethod, "GET")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Error (fake) getting interactions: \(error)")
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testGetConfiguration() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")

        let expectation = XCTestExpectation()
        let _ = client.request(ApptentiveAPI.getConfiguration(with: self.anonymousCredentials)) { (result: Result<ConversationResponse, Error>) in
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url, baseURL.appendingPathComponent("conversations/def/configuration"))
            XCTAssertEqual(requestor.request?.httpMethod, "GET")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Error (fake) getting configuration: \(error)")
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    func testGetMessages() throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")

        let expectation = XCTestExpectation()
        let _ = client.request(ApptentiveAPI.getMessages(with: self.anonymousCredentials, afterMessageWithID: "last_message_id", pageSize: "5")) { (result: Result<ConversationResponse, Error>) in
            XCTAssertNotNil(requestor.request)
            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?.isEmpty, false)
            XCTAssertEqual(requestor.request?.url?.absoluteString, "http://example.com/conversations/def/messages?starts_after=last_message_id&page_size=5")
            XCTAssertEqual(requestor.request?.httpMethod, "GET")

            XCTAssertEqual(requestor.request?.allHTTPHeaderFields?["User-Agent"], "Apptentive/1.2.3 (Apple)")

            switch result {
            case .success:
                break
            case .failure(let error):
                XCTFail("Error (fake) getting messages: \(error)")
            }

            expectation.fulfill()
        }

        self.wait(for: [expectation], timeout: 5)
    }

    static func parseMultipartBody(_ body: Data, boundary boundaryString: String) throws -> [BodyPart] {
        let boundary = boundaryString.data(using: .utf8)!
        let crlf = "\r\n".data(using: .utf8)!
        let dashes = "--".data(using: .utf8)!

        var index = 0
        var result = [BodyPart]()

        while index < body.count {
            var partRange: Range<Data.Index>

            if let firstBoundaryIndex = body.range(of: dashes + boundary + crlf, in: 0..<body.count), index == 0 {
                index = firstBoundaryIndex.endIndex
                continue
            } else if let nextBoundaryIndex = body.range(of: crlf + dashes + boundary + crlf, in: index..<body.count) {
                partRange = index..<nextBoundaryIndex.startIndex
                index = nextBoundaryIndex.endIndex
            } else if let finalBoundaryIndex = body.range(of: crlf + dashes + boundary + dashes, in: index..<body.count) {
                partRange = index..<finalBoundaryIndex.startIndex
                index = body.count
            } else {
                throw MultipartDecodingError.invalidBoundary
            }

            result.append(try self.parseMultipartPart(body.subdata(in: partRange)))
        }

        return result
    }

    static func parseMultipartPart(_ part: Data) throws -> BodyPart {
        let crlf = "\r\n".data(using: .utf8)!
        var headers = [String: String]()

        var currentIndex = 0

        while currentIndex < part.count {
            guard let nextCRLFIndex = part.range(of: crlf, in: currentIndex..<part.count) else {
                throw MultipartDecodingError.invalidHeader
            }

            let line = part[currentIndex..<nextCRLFIndex.startIndex]

            currentIndex = nextCRLFIndex.endIndex

            if line.isEmpty {
                // End of headers
                break
            }

            let header = String(data: line, encoding: .utf8)!
            let parts = header.split(separator: ":")

            guard parts.count == 2 else {
                throw MultipartDecodingError.invalidHeader
            }

            let headerName = parts[0].trimmingCharacters(in: .whitespaces)
            let headerValue = parts[1].trimmingCharacters(in: .whitespaces)

            headers[headerName] = headerValue
        }

        let content = part.suffix(from: currentIndex)

        return BodyPart(headers: headers, content: content)
    }

    struct BodyPart {
        let headers: [String: String]
        let content: Data
    }

    struct MockHTTPBodyPart: Codable, Equatable, HTTPBodyPart {
        var contentType: String = HTTPContentType.json

        var filename: String? = nil

        var parameterName: String? = nil

        func content(using encoder: JSONEncoder) throws -> Data {
            return try encoder.encode(self)
        }

        let foo: String
        let bar: String
    }
}

enum MultipartDecodingError: Error {
    case invalidBoundary
    case invalidHeader
}
