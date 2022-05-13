//
//  Payload.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Stores the information needed to potentially make a deferred update to the Apptentive API.
///
/// Payload objects are enqueued onto a payload queue and sent by the ``PayloadSender`` object.
///
/// The response from payload API requests are not used other than to confirm that the payload was
/// sent successfully or that the failure in sending was unrecoverable (indicating that the request should
/// not be retried).
struct Payload: Codable, Equatable, CustomDebugStringConvertible {
    /// Represents the HTTP request body to use for the API request.
    let jsonObject: JSONObject

    /// The HTTP method to use for the API request.
    let method: HTTPMethod

    /// The path to use to build the URL for the API request.
    let path: String

    /// The attachments to send along with the request, if any.
    let attachments: [Attachment]

    /// Generates nonces, creation dates, UTC offsets, and stores session ID.
    static var context = Context()

    /// The parts making up the body of the HTTP request.
    ///
    /// This array will contain a single item except for payloads that include attachments.
    var bodyParts: [HTTPBodyPart] {
        return [self.jsonObject] + self.attachments
    }

    var debugDescription: String {
        return "Payload(\(self.method) to \(self.path))"
    }
    /// Creates a new payload to add a survey response.
    /// - Parameter surveyResponse: The survey response to add.
    init(wrapping surveyResponse: SurveyResponse) {
        self.init(specializedJSONObject: .surveyResponse(SurveyResponseContent(with: surveyResponse)), path: "surveys/\(surveyResponse.surveyID)/responses", method: .post)
    }

    /// Creates a new payload to add an event.
    /// - Parameter event: The event to add.
    init(wrapping event: Event) {
        self.init(specializedJSONObject: .event(EventContent(with: event)), path: "events", method: .post)
    }

    /// Creates a new payload to update the person.
    /// - Parameter person: The data with which to update the person.
    init(wrapping person: Person) {
        self.init(specializedJSONObject: .person(PersonContent(with: person)), path: "person", method: .put)
    }

    /// Creates a new payload to update the device.
    /// - Parameter device: The data with which to update the device.
    init(wrapping device: Device) {
        self.init(specializedJSONObject: .device(DeviceContent(with: device)), path: "device", method: .put)
    }

    /// Creates a new payload to update the app release.
    /// - Parameter appRelease: The data with which to update the app release.
    init(wrapping appRelease: AppRelease) {
        self.init(specializedJSONObject: .appRelease(AppReleaseContent(with: appRelease)), path: "app_release", method: .put)
    }

    /// - Parameter message:

    /// Creates a new payload to send a message.
    /// - Parameters:
    ///   - message: The message to send.
    ///   - customData: The custom data to attach to the message.
    ///   - attachmentURLProvider: An object conforming to `AttachmentURLProviding` to provide the URL for any stored attachments.
    init(wrapping message: MessageList.Message, customData: CustomData? = nil, attachmentURLProvider: AttachmentURLProviding) {
        let attachments = message.attachments.compactMap { (attachment: MessageList.Message.Attachment) -> Payload.Attachment? in
            var contents: Attachment.AttachmentContents

            if let url = attachmentURLProvider.url(for: attachment) {
                contents = .file(url)
            } else if case .inMemory(let data) = attachment.storage {
                contents = .data(data)
            } else {
                assertionFailure("Unexpected attachment storage type for outgoing message.")
                return nil
            }

            return Attachment(contentType: attachment.contentType, filename: attachment.filename, contents: contents)
        }

        self.init(specializedJSONObject: .message(MessageContent(with: message, customData: customData)), path: "messages", method: .post, attachments: attachments)
    }

    /// Initializes a new payload.
    /// - Parameters:
    ///   - specializedJSONObject: The payload-type-specific object used to create the JSON object.
    ///   - path: The path for the API request.
    ///   - method: The HTTP method for the API request.
    ///   - attachments: The attachments to send with the payload, if any.
    private init(specializedJSONObject: SpecializedJSONObject, path: String, method: HTTPMethod, attachments: [Attachment] = []) {
        self.jsonObject = JSONObject(specializedJSONObject: specializedJSONObject, context: Self.context, shouldStripContainer: attachments.count > 0)
        self.path = path
        self.method = method
        self.attachments = attachments
    }

    struct Context {
        func getNextNonce() -> String {
            return UUID().uuidString
        }

        var date: Date {
            return Date()
        }

        var utcOffset: Int {
            return TimeZone.current.secondsFromGMT()
        }

        mutating func startSession() {
            self.sessionID = UUID().uuidString
        }

        mutating func endSession() {
            self.sessionID = nil
        }

        var sessionID: String?
    }

    /// Represents JSON request data and augments it with universal parameters for the Apptentive API.
    struct JSONObject: Codable, Equatable, HTTPBodyPart {
        /// The per-type payload content that should be wrapped.
        let specializedJSONObject: SpecializedJSONObject

        /// A unique string that identifies this payload for deduplication on the server.
        let nonce: String

        /// The date/time at which the payload was created.
        let creationDate: Date

        /// The offset (in seconds) from UTC for the creation date.
        let creationUTCOffset: Int

        /// Whether the outer JSON container should be removed.
        ///
        /// This is true for JSON that will be included in a multipart request.
        /// For multipart requests, the key for the container is used as the part's name.
        let shouldStripContainer: Bool

        /// A string that uniquely identifies a particular launch (warm or cold) of the app.
        let sessionID: String?

        /// The name for JSON that will be included in a multipart request.
        ///
        /// Used as the value for the `name` attribute of the part's `Content-Disposition` header.
        var parameterName: String? {
            return self.shouldStripContainer ? self.specializedJSONObject.containerKey.rawValue : nil
        }

        var filename: String? = nil

        var contentType: String {
            return HTTPContentType.json
        }

        func content(using encoder: JSONEncoder) throws -> Data {
            return try encoder.encode(self)
        }

        init(specializedJSONObject: SpecializedJSONObject, context: Context, shouldStripContainer: Bool = false) {
            self.specializedJSONObject = specializedJSONObject
            self.shouldStripContainer = shouldStripContainer

            self.nonce = context.getNextNonce()
            self.creationDate = context.date
            self.creationUTCOffset = context.utcOffset
            self.sessionID = context.sessionID
        }

        init(from decoder: Decoder) throws {
            var nestedContainer: KeyedDecodingContainer<Payload.AllPossibleCodingKeys>

            let container = try decoder.container(keyedBy: PayloadTypeCodingKeys.self)

            if let containerKey = container.allKeys.first {
                switch containerKey {
                case .response:
                    self.specializedJSONObject = .surveyResponse(try container.decode(SurveyResponseContent.self, forKey: containerKey))

                case .event:
                    self.specializedJSONObject = .event(try container.decode(EventContent.self, forKey: containerKey))

                case .person:
                    self.specializedJSONObject = .person(try container.decode(PersonContent.self, forKey: containerKey))

                case .device:
                    self.specializedJSONObject = .device(try container.decode(DeviceContent.self, forKey: containerKey))

                case .appRelease:
                    self.specializedJSONObject = .appRelease(try container.decode(AppReleaseContent.self, forKey: containerKey))

                case .message:
                    self.specializedJSONObject = .message(try container.decode(MessageContent.self, forKey: containerKey))
                }

                nestedContainer = try container.nestedContainer(keyedBy: Payload.AllPossibleCodingKeys.self, forKey: containerKey)

                self.shouldStripContainer = false
            } else {
                nestedContainer = try decoder.container(keyedBy: Payload.AllPossibleCodingKeys.self)

                self.specializedJSONObject = .message(try MessageContent.init(from: decoder))

                self.shouldStripContainer = true
            }

            self.nonce = try nestedContainer.decode(String.self, forKey: .nonce)
            self.creationDate = try nestedContainer.decode(Date.self, forKey: .creationDate)
            self.creationUTCOffset = try nestedContainer.decode(Int.self, forKey: .creationUTCOffset)
            self.sessionID = try nestedContainer.decodeIfPresent(String.self, forKey: .sessionID)
        }

        /// Encodes the payload to the specified encoder.
        ///
        /// Because of the format expected by the Apptentive API, the encoding process is unusual:
        /// First it creates an outer container with a single key (from `PayloadTypeCodingKeys`)
        /// that contains a nested container which uses a union of the set of coding keys of all
        /// payload types, plus the boilerplate keys. The encoder then encodes the boilerplate parameters
        /// common to all payload types. Finally it asks the payload contents to encode themselves
        /// to the nested container via the `PayloadEncodable` protocol.
        ///
        /// An extra wrinkle is that for multipart requests, the outer container is left off, and what
        /// would normally be the key for that container is used as the value for the `name` field
        /// of the `Content-Disposition` header.
        /// - Parameter encoder: the encoder to use to encode the payload.
        /// - Throws: An error if the coding keys are invalid or a value could not be encoded.
        func encode(to encoder: Encoder) throws {
            var container: KeyedEncodingContainer<Payload.AllPossibleCodingKeys>

            if self.shouldStripContainer {
                // For multipart requests, the outer container is left off.
                container = encoder.container(keyedBy: Payload.AllPossibleCodingKeys.self)
            } else {
                var encodingContainer = encoder.container(keyedBy: PayloadTypeCodingKeys.self)
                container = encodingContainer.nestedContainer(keyedBy: Payload.AllPossibleCodingKeys.self, forKey: self.specializedJSONObject.containerKey)
            }

            try container.encode(self.nonce, forKey: .nonce)
            try container.encode(self.creationDate, forKey: .creationDate)
            try container.encode(self.creationUTCOffset, forKey: .creationUTCOffset)
            try container.encodeIfPresent(self.sessionID, forKey: .sessionID)

            try self.specializedJSONObject.encodeContents(to: &container)
        }

        enum PayloadTypeCodingKeys: String, CodingKey {
            case response
            case event
            case person
            case device
            case appRelease = "app_release"
            case message
        }
    }

    /// Represents per-type JSON request data for the Apptentive API.
    enum SpecializedJSONObject: Equatable {
        case surveyResponse(SurveyResponseContent)
        case event(EventContent)
        case person(PersonContent)
        case device(DeviceContent)
        case appRelease(AppReleaseContent)
        case message(MessageContent)

        var containerKey: JSONObject.PayloadTypeCodingKeys {
            switch self {
            case .surveyResponse:
                return .response

            case .event:
                return .event

            case .person:
                return .person

            case .device:
                return .device

            case .appRelease:
                return .appRelease

            case .message:
                return .message
            }
        }

        func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws {
            switch self {
            case .surveyResponse(let surveyResponseContents):
                try surveyResponseContents.encodeContents(to: &container)

            case .event(let eventContents):
                try eventContents.encodeContents(to: &container)

            case .person(let personContents):
                try personContents.encodeContents(to: &container)

            case .device(let deviceContents):
                try deviceContents.encodeContents(to: &container)

            case .appRelease(let appReleaseContents):
                try appReleaseContents.encodeContents(to: &container)

            case .message(let messageContents):
                try messageContents.encodeContents(to: &container)
            }
        }
    }

    /// The union of coding keys from all payload types.
    enum AllPossibleCodingKeys: String, CodingKey {
        // Ubiquitous keys
        case nonce
        case creationDate = "client_created_at"
        case creationUTCOffset = "client_created_at_utc_offset"
        case sessionID = "session_id"

        // Shared keys
        case customData = "custom_data"

        // Survey response keys
        case answers

        // Event keys
        case label
        case interactionID = "interaction_id"
        case userInfo = "data"
        case time
        case location
        case commerce
        case eventCustomData

        // Person keys
        case emailAddress = "email"
        case name
        case mParticleID = "mparticle_id"

        // Device keys
        case uuid
        case osName = "os_name"
        case osVersion = "os_version"
        case osBuild = "os_build"
        case hardware
        case carrier
        case contentSizeCategory = "content_size_category"
        case localeRaw = "locale_raw"
        case localeCountryCode = "locale_country_code"
        case localeLanguageCode = "locale_language_code"
        case utcOffset = "utc_offset"
        case integrationConfiguration = "integration_config"
        case advertisingIdentifier = "advertiser_id"

        // App release keys
        case type
        case bundleIdentifier = "cf_bundle_identifier"
        case version = "cf_bundle_short_version_string"
        case build = "cf_bundle_version"
        case appStoreReceipt = "app_store_receipt"
        case isDebugBuild = "debug"
        case isOverridingStyles = "overriding_styles"
        case deploymentTarget = "deployment_target"
        case compiler = "dt_compiler"
        case platformBuild = "dt_platform_build"
        case platformName = "dt_platform_name"
        case platformVersion = "dt_platform_version"
        case sdkBuild = "dt_sdk_build"
        case sdkName = "dt_sdk_name"
        case xcode = "dt_xcode"
        case xcodeBuild = "dt_xcode_build"
        case sdkVersion = "sdk_version"
        case sdkProgrammingLanguage = "sdk_programming_language"
        case sdkAuthorName = "sdk_author_name"
        case sdkPlatform = "sdk_platform"
        case sdkDistributionVersion = "sdk_distribution_version"
        case sdkDistributionName = "sdk_distribution"

        // Message keys
        case body
        case isAutomated = "automated"
        case isHidden = "hidden"
    }

    /// Describes the media attachment assoiciated with each message.
    struct Attachment: Codable, Equatable, HTTPBodyPart {
        /// The value for the `name` part of the `Content-Disposition` header.
        var parameterName: String? = "file[]"
        /// The value for the `Content-Type` header.
        var contentType: String
        /// The filename to use in the `Content-Disposition` header.
        let filename: String?
        /// The URL for the file type.
        let contents: AttachmentContents

        func content(using encoder: JSONEncoder) throws -> Data {
            switch self.contents {
            case .file(let url):
                return try Data(contentsOf: url)
            case .data(let data):
                return data
            }
        }

        enum AttachmentContents: Codable, Equatable {
            case file(URL)
            case data(Data)
        }
    }
}

/// Describes an object that can encode its contents
/// (which must be added to the `AllPossiblePayloadCodingKeys` enumeration)
/// to an existing keyed encoding container.
protocol PayloadEncodable {
    /// Encodes the object's contents to the specified keyed encoding container.
    /// - Parameter container: The keyed encoding container that will be used to encode the object's contents.
    /// - Throws: An error if the encoding fails.
    func encodeContents(to container: inout KeyedEncodingContainer<Payload.AllPossibleCodingKeys>) throws
}

/// An empty object corresponding to the expected response when sending a payload.
struct PayloadResponse: Codable {}
