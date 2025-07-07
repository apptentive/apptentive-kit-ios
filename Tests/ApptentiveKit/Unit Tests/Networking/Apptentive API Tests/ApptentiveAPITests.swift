//
//  ApptentiveAPITests.swift
//  ApptentiveTests
//
//  Created by Frank Schmitt on 2/21/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

struct ApptentiveAPITests {
    var payloadContext: Payload.Context!
    var pendingCredentials = PendingAPICredentials(appCredentials: .init(key: "abc", signature: "123"))
    var anonymousCredentials = AnonymousAPICredentials(appCredentials: .init(key: "abc", signature: "123"), conversationCredentials: .init(id: "def", token: "456"))

    init() throws {
        self.payloadContext = Payload.Context(
            tag: ".", credentials: .header(id: anonymousCredentials.conversationCredentials.id, token: anonymousCredentials.conversationCredentials.token), sessionID: "abc123", encoder: JSONEncoder.apptentive, encryptionContext: nil)
    }

    final class MockAppCredentialsProvider: PayloadAuthenticationDelegate {
        var appCredentials: Apptentive.AppCredentials? {
            return .init(key: "abc", signature: "123")
        }

        func authenticationDidFail(with errorResponse: ErrorResponse?) {}
    }

    @Test func testBuildHeaders() {
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

        #expect(headers == expectedHeaders)
    }

    @Test func testBuildRequest() throws {
        let path = "foo"
        let method = HTTPMethod.delete
        let bodyObject = MockHTTPBodyPart(foo: "foo", bar: "bar")
        let baseURL = URL(string: "https://api.example.com/")!

        let endpoint = ApptentiveAPI(credentials: self.anonymousCredentials, path: path, method: method, bodyObject: bodyObject)

        let request = try endpoint.buildRequest(baseURL: baseURL, userAgent: "Apptentive/1.2.3 (Apple)", languageCode: "de")

        let expectedHeaders = [
            "APPTENTIVE-KEY": "abc",
            "APPTENTIVE-SIGNATURE": "123",
            "X-API-Version": "15",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "application/json;charset=UTF-8",
            "Authorization": "Bearer 456",
            "Accept": "application/json;charset=UTF-8",
            "Accept-Charset": "UTF-8",
            "Accept-Language": "de",
        ]

        #expect(request.url == URL(string: "https://api.example.com/conversations/def/foo")!)
        #expect(request.httpMethod == method.rawValue)
        #expect(request.allHTTPHeaderFields == expectedHeaders)
    }

    @Test func testBuildMultipartRequest() throws {
        let path = "foo"
        let method = HTTPMethod.delete
        let bodyObject = MockHTTPBodyPart(foo: "foo", bar: "bar")
        let baseURL = URL(string: "https://api.example.com/")!

        let part1 = bodyObject

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: BundleFinder.self), compatibleWith: nil)!
        let data1 = image1.pngData()!
        let part2 = Payload.Attachment(contentType: "image/png", filename: "logo", contents: .data(data1))

        let image2 = UIImage(named: "dog", in: Bundle(for: BundleFinder.self), compatibleWith: nil)!
        let data2 = image2.jpegData(compressionQuality: 0.5)!
        let part3 = Payload.Attachment(contentType: "image/jpeg", filename: "dog", contents: .data(data2))

        let endpoint = ApptentiveAPI(credentials: self.anonymousCredentials, path: path, method: method, bodyParts: [part1, part2, part3])

        let request = try endpoint.buildRequest(baseURL: baseURL, userAgent: "Apptentive/1.2.3 (Apple)", languageCode: "de")

        let expectedHeaders = [
            "APPTENTIVE-KEY": "abc",
            "APPTENTIVE-SIGNATURE": "123",
            "X-API-Version": "15",
            "User-Agent": "Apptentive/1.2.3 (Apple)",
            "Content-Type": "multipart/mixed; boundary=\(endpoint.boundaryString)",
            "Authorization": "Bearer 456",
            "Accept": "application/json;charset=UTF-8",
            "Accept-Charset": "UTF-8",
            "Accept-Language": "de",
        ]

        #expect(request.url == URL(string: "https://api.example.com/conversations/def/foo")!)
        #expect(request.httpMethod == method.rawValue)
        #expect(request.allHTTPHeaderFields == expectedHeaders)

        let parts = try Self.parseMultipartBody(request.httpBody!, boundary: endpoint.boundaryString)

        #expect(parts.count == 3)

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

        #expect(parts[0].headers == expectedPartHeaders[0])
        #expect(parts[1].headers == expectedPartHeaders[1])
        #expect(parts[2].headers == expectedPartHeaders[2])

        let decodedBodyObject = try JSONDecoder.apptentive.decode(MockHTTPBodyPart.self, from: parts[0].content)
        #expect(bodyObject == decodedBodyObject)
        #expect(parts[1].content == data1)
        #expect(parts[2].content == data2)
    }

    @Test func testBuildUserAgent() {
        let userAgent = ApptentiveAPI.userAgent(sdkVersion: "1.2.3")

        #expect(userAgent == "Apptentive/1.2.3 (Apple)")
    }

    @Test func testParseExpiry() throws {
        let response1 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Cache-Control": "max-age = 86400"])!

        guard let expiry1 = ApptentiveAPI.parseExpiry(response1) else {
            throw TestError(reason: "Unable to parse valid expiry")
        }

        #expect((expiry1.timeIntervalSinceNow == Date(timeIntervalSinceNow: 86400).timeIntervalSinceNow) ± 1.0)

        let response2 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["Cache-control": "axmay-agehay: 86400"])!

        let expiry2 = ApptentiveAPI.parseExpiry(response2)

        #expect(expiry2 == nil)

        #expect((expiry1.timeIntervalSinceNow == Date(timeIntervalSinceNow: 86400).timeIntervalSinceNow) ± 1.0)

        let response3 = HTTPURLResponse(url: URL(string: "https://api.apptentive.com/foo")!, statusCode: 200, httpVersion: "1.1", headerFields: ["cAcHe-cOnTrOl": "max-age = 650"])!

        guard let expiry3 = ApptentiveAPI.parseExpiry(response3) else {
            throw TestError(reason: "Unable to parse valid expiry (with weird case)")
        }

        #expect((expiry3.timeIntervalSinceNow == Date(timeIntervalSinceNow: 650).timeIntervalSinceNow) ± 1.0)
    }

    @Test func testCreateConversation() async throws {
        let baseURL = URL(string: "http://example.com")!
        let conversation = Conversation(dataProvider: MockDataProvider())
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")

        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("conversations"), statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        let _ = try await client.request(ApptentiveAPI.createConversation(conversation, with: self.pendingCredentials, token: nil))

        let request = await requestor.request

        #expect(request != nil)
        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
        #expect(request?.url == baseURL.appendingPathComponent("conversations"))
        #expect(request?.httpMethod == "POST")
        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")
    }

    @Test func testCreateSurveyResponse() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let requestRetrier = HTTPRequestRetrier()
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        await payloadSender.setAuthenticationDelegate(appCredentialsProvider)
        await payloadSender.setAppCredentials(appCredentialsProvider.appCredentials)
        await requestRetrier.setClient(client)

        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("conversations"), statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        let surveyResponse = SurveyResponse(surveyID: "789", questionResponses: ["1": .answered([Answer.freeform("foo")])])

        await withCheckedContinuation { continuation in
            Task {
                await requestor.setExtraCompletion { requestor in
                    Task {
                        let request = await requestor.request

                        #expect(request != nil)
                        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
                        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/surveys/789/responses"))
                        #expect(request?.httpMethod == "POST")
                        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")

                        continuation.resume()
                    }
                }

                try await payloadSender.send(Payload(wrapping: surveyResponse, with: self.payloadContext))
            }
        }
    }

    @Test func testCreateEvent() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let requestRetrier = HTTPRequestRetrier()
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        await payloadSender.setAuthenticationDelegate(appCredentialsProvider)
        await payloadSender.setAppCredentials(appCredentialsProvider.appCredentials)
        await requestRetrier.setClient(client)

        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("events"), statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        let event = Event(name: "Foobar")

        await withCheckedContinuation { continuation in
            Task {
                await requestor.setExtraCompletion { requestor in
                    Task {
                        let request = await requestor.request

                        #expect(request != nil)
                        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
                        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/events"))
                        #expect(request?.httpMethod == "POST")
                        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")

                        continuation.resume()
                    }
                }

                try await payloadSender.send(Payload(wrapping: event, with: self.payloadContext))
            }
        }
    }

    @Test func testUpdatePerson() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let requestRetrier = HTTPRequestRetrier()
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        await payloadSender.setAuthenticationDelegate(appCredentialsProvider)
        await payloadSender.setAppCredentials(appCredentialsProvider.appCredentials)
        await requestRetrier.setClient(client)

        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("person"), statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        var customData = CustomData()
        customData["foo"] = "bar"
        customData["number"] = 2
        customData["bool"] = false

        let person = Person(name: "Testy McTestface", emailAddress: "test@example.com", mParticleID: nil, customData: customData)

        await withCheckedContinuation { continuation in
            Task {
                await requestor.setExtraCompletion { requestor in
                    Task {
                        let request = await requestor.request

                        #expect(request != nil)
                        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
                        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/person"))
                        #expect(request?.httpMethod == "PUT")
                        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")

                        continuation.resume()
                    }
                }

                try await payloadSender.send(Payload(wrapping: person, with: self.payloadContext))
            }
        }
    }

    @Test func testUpdateDevice() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let requestRetrier = HTTPRequestRetrier()
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        await payloadSender.setAuthenticationDelegate(appCredentialsProvider)
        await payloadSender.setAppCredentials(appCredentialsProvider.appCredentials)
        await requestRetrier.setClient(client)

        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("device"), statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        var customData = CustomData()
        customData["foo"] = "bar"
        customData["number"] = 2
        customData["bool"] = false

        var deviceTemp = Device(dataProvider: MockDataProvider())
        deviceTemp.customData = customData

        let device = deviceTemp

        await withCheckedContinuation { continuation in
            Task {
                await requestor.setExtraCompletion { requestor in
                    Task {
                        let request = await requestor.request

                        #expect(request != nil)
                        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
                        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/device"))
                        #expect(request?.httpMethod == "PUT")
                        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")

                        continuation.resume()
                    }
                }

                try await payloadSender.send(Payload(wrapping: device, with: self.payloadContext))
            }
        }
    }

    @Test func testUpdateAppRelease() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let requestRetrier = HTTPRequestRetrier()
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        await payloadSender.setAuthenticationDelegate(appCredentialsProvider)
        await payloadSender.setAppCredentials(appCredentialsProvider.appCredentials)
        await requestRetrier.setClient(client)

        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("app_release"), statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        let appRelease = AppRelease(dataProvider: MockDataProvider())

        await withCheckedContinuation { continuation in
            Task {
                await requestor.setExtraCompletion { requestor in
                    Task {
                        let request = await requestor.request

                        #expect(request != nil)
                        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
                        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/app_release"))
                        #expect(request?.httpMethod == "PUT")
                        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")

                        continuation.resume()
                    }
                }

                try await payloadSender.send(Payload(wrapping: appRelease, with: self.payloadContext))
            }
        }
    }

    @Test func testCreateMessage() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: Data())
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        let requestRetrier = HTTPRequestRetrier()
        let payloadSender = PayloadSender(requestRetrier: requestRetrier, notificationCenter: NotificationCenter.default)
        let appCredentialsProvider = MockAppCredentialsProvider()
        await payloadSender.setAuthenticationDelegate(appCredentialsProvider)
        await payloadSender.setAppCredentials(appCredentialsProvider.appCredentials)
        await requestRetrier.setClient(client)

        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("messages"), statusCode: 201, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        var customData = CustomData()
        customData["foo"] = "bar"
        customData["number"] = 2
        customData["bool"] = false

        let image1 = UIImage(named: "apptentive-logo", in: Bundle(for: BundleFinder.self), compatibleWith: nil)!
        let image2 = UIImage(named: "dog", in: Bundle(for: BundleFinder.self), compatibleWith: nil)!

        let data1 = image1.pngData()!
        let data2 = image2.jpegData(compressionQuality: 0.5)!

        let attachment1 = MessageList.Message.Attachment(contentType: "image/png", filename: "apptentive-logo", storage: .inMemory(data1))
        let attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "dog", storage: .inMemory(data2))

        let message = MessageList.Message(nonce: "draft", body: "Test Message", attachments: [attachment1, attachment2], status: .draft)

        await withCheckedContinuation { continuation in
            Task {
                await requestor.setExtraCompletion { requestor in
                    Task {
                        let request = await requestor.request

                        #expect(request != nil)
                        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
                        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/messages"))
                        #expect(request?.httpMethod == "POST")
                        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")

                        do {
                            // get boundary from content type `multipart/mixed; boundary=<boundary>`
                            guard let contentType = request?.allHTTPHeaderFields?["Content-Type"],
                                let boundaryAttribute = contentType.components(separatedBy: "; ").last,
                                let boundary = boundaryAttribute.components(separatedBy: "=").last
                            else {
                                throw TestError(reason: "Unable to get boundary from Content-Type header.")
                            }

                            guard let body = request?.httpBody else {
                                throw TestError(reason: "No multipart body.")
                            }

                            let parts = try Self.parseMultipartBody(body, boundary: boundary)

                            #expect(parts[0].headers["Content-Type"] == "application/json;charset=UTF-8")
                            #expect(parts[0].headers["Content-Disposition"] == "form-data; name=\"message\"")
                            let message = try JSONDecoder.apptentive.decode(Payload.JSONObject.self, from: parts[0].content)

                            guard case Payload.SpecializedJSONObject.message(let messageContent) = message.specializedJSONObject else {
                                throw TestError(reason: "Message payload doesn't contain message stuff")
                            }

                            #expect(messageContent.body == "Test Message")

                            #expect(parts[1].headers["Content-Type"] == "image/png")
                            #expect(parts[1].headers["Content-Disposition"] == "form-data; name=\"file[]\"; filename=\"apptentive-logo\"")
                            #expect(parts[1].content == data1)

                            #expect(parts[2].headers["Content-Type"] == "image/jpeg")
                            #expect(parts[2].headers["Content-Disposition"] == "form-data; name=\"file[]\"; filename=\"dog\"")
                            #expect(parts[2].content == data2)

                            continuation.resume()
                        } catch let error {
                            Issue.record("Error decoding multipart body: \(error).")
                        }
                    }
                }

                let payload = try Payload(wrapping: message, with: self.payloadContext, customData: nil, attachmentURLProvider: MockAttachmentURLProviding())
                await payloadSender.send(payload)
            }
        }
    }

    @Test func testGetInteractions() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("conversations/def/interactions"), statusCode: 200, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        let _ = try await client.request(ApptentiveAPI.getInteractions(with: self.anonymousCredentials))
        let request = await requestor.request

        #expect(request != nil)
        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/interactions"))
        #expect(request?.httpMethod == "GET")
        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")
    }

    @Test func testGetConfiguration() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("conversations/def/configuration"), statusCode: 200, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        let _ = try await client.request(ApptentiveAPI.getConfiguration(with: self.anonymousCredentials))
        let request = await requestor.request

        #expect(request != nil)
        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
        #expect(request?.url == baseURL.appendingPathComponent("conversations/def/configuration"))
        #expect(request?.httpMethod == "GET")
        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")
    }

    @Test func testGetMessages() async throws {
        let baseURL = URL(string: "http://example.com")!
        let requestor = SpyRequestor(responseData: try JSONEncoder.apptentive.encode(ConversationResponse(token: "abc", id: "123", deviceID: "456", personID: "789", encryptionKey: nil)))
        let client = HTTPClient(requestor: requestor, baseURL: baseURL, userAgent: ApptentiveAPI.userAgent(sdkVersion: "1.2.3"), languageCode: "de")
        await requestor.setResponse(HTTPURLResponse(url: baseURL.appendingPathComponent("http://example.com/conversations/def/messages?starts_after=last_message_id&page_size=5"), statusCode: 200, httpVersion: "1.1", headerFields: [:]))
        await requestor.setResponseData(Data())

        let _ = try await client.request(ApptentiveAPI.getMessages(with: self.anonymousCredentials, afterMessageWithID: "last_message_id", pageSize: "5"))
        let request = await requestor.request

        #expect(request != nil)
        #expect(request?.allHTTPHeaderFields?.isEmpty == false)
        #expect(request?.url?.absoluteString == "http://example.com/conversations/def/messages?starts_after=last_message_id&page_size=5")
        #expect(request?.httpMethod == "GET")
        #expect(request?.allHTTPHeaderFields?["User-Agent"] == "Apptentive/1.2.3 (Apple)")
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
