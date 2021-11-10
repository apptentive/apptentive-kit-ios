//
//  Payload.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 9/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents an update request to be sent to the Apptentive API.
///
/// Payload objects are enqueued onto a payload queue and sent by the ``PayloadSender`` object.
///
/// The response from payload API requests are not used other than to confirm that the payload was
/// sent successfully or that the failure in sending was unrecoverable (indicating that the request should
/// not be retried).
struct Payload: Codable, Equatable, CustomDebugStringConvertible {
    /// The payload contents that should be wrapped.
    let contents: PayloadContents

    /// A unique string that identifies this payload for deduplication on the server.
    let nonce: String

    /// The date/time at which the payload was created.
    let creationDate: Date

    /// The offset (in seconds) from UTC for the creation date.
    let creationUTCOffset: Int

    /// The HTTP method to use for the API request.
    let method: HTTPMethod

    /// The path to use to build the URL for the API request.
    let path: String

    /// Creates a new payload object that wraps a survey response.
    /// - Parameter surveyResponse: The survey response to wrap.
    init(wrapping surveyResponse: SurveyResponse) {
        self.init(contents: .surveyResponse(SurveyResponseContents(with: surveyResponse)), path: "surveys/\(surveyResponse.surveyID)/responses", method: .post)
    }

    /// Creates a new payload object that wraps an event.
    /// - Parameter event: The event to wrap.
    init(wrapping event: Event) {
        self.init(contents: .event(EventContents(with: event)), path: "events", method: .post)
    }

    init(wrapping person: Person) {
        self.init(contents: .person(PersonContents(with: person)), path: "person", method: .put)
    }

    init(wrapping device: Device) {
        self.init(contents: .device(DeviceContents(with: device)), path: "device", method: .put)
    }

    init(wrapping appRelease: AppRelease) {
        self.init(contents: .appRelease(AppReleaseContents(with: appRelease)), path: "app_release", method: .put)
    }

    init(wrapping message: Message) {
        self.init(contents: .message(MessageContents(with: message)), path: "messages", method: .post)
    }

    var bodyParts: [HTTPBodyPart] {
        if self.contents.additionalBodyParts.isEmpty {
            return [.jsonEncoded(self)]
        } else {
            // For multipart requests, the JSON container is stripped off and the key is moved to the part name.
            return [.jsonEncoded(self, name: self.contents.containerKey.rawValue)] + self.contents.additionalBodyParts
        }
    }

    /// Initializes a new payload.
    /// - Parameters:
    ///   - contents: The contents of the payload.
    ///   - path: The path for the API request.
    ///   - method: The HTTP method for the API request.
    private init(contents: PayloadContents, path: String, method: HTTPMethod) {
        self.nonce = UUID().uuidString
        self.creationDate = Date()
        self.creationUTCOffset = TimeZone.current.secondsFromGMT()

        self.contents = contents
        self.path = path
        self.method = method
    }

    /// Creates an object using data from the decoder.
    ///
    /// This implementation is only intended for testing. As such the decoded objects may differ from
    /// the objects that were previously encoded.
    /// - Parameter decoder: The decoder from which to request data.
    /// - Throws: An error if the coding keys are invalid or a value could not be decoded.
    init(from decoder: Decoder) throws {
        var nestedContainer: KeyedDecodingContainer<AllPossiblePayloadCodingKeys>

        let container = try decoder.container(keyedBy: PayloadTypeCodingKeys.self)

        if let containerKey = container.allKeys.first {
            switch containerKey {
            case .response:
                self.contents = .surveyResponse(try container.decode(SurveyResponseContents.self, forKey: containerKey))
                self.path = "surveys/<survey_id>/responses"
                self.method = .post

            case .event:
                self.contents = .event(try container.decode(EventContents.self, forKey: containerKey))
                self.path = "events"
                self.method = .post

            case .person:
                self.contents = .person(try container.decode(PersonContents.self, forKey: containerKey))
                self.path = "person"
                self.method = .put

            case .device:
                self.contents = .device(try container.decode(DeviceContents.self, forKey: containerKey))
                self.path = "device"
                self.method = .put

            case .appRelease:
                self.contents = .appRelease(try container.decode(AppReleaseContents.self, forKey: containerKey))
                self.path = "app_release"
                self.method = .put

            case .message:
                self.contents = .message(try container.decode(MessageContents.self, forKey: containerKey))
                self.path = "messages"
                self.method = .post
            }

            nestedContainer = try container.nestedContainer(keyedBy: AllPossiblePayloadCodingKeys.self, forKey: containerKey)
        } else {
            // If the outer container has no container key, assume this was multipart.
            nestedContainer = try decoder.container(keyedBy: AllPossiblePayloadCodingKeys.self)

            let body = try nestedContainer.decode(String.self, forKey: .body)
            let isAutomated = try nestedContainer.decode(Bool.self, forKey: .isAutomated)
            let isHidden = try nestedContainer.decode(Bool.self, forKey: .isHidden)

            self.contents = .message(MessageContents(with: Message(body: body, isHidden: isHidden, isAutomated: isAutomated)))
            self.path = "messages"
            self.method = .post
        }

        self.nonce = try nestedContainer.decode(String.self, forKey: .nonce)
        self.creationDate = try nestedContainer.decode(Date.self, forKey: .creationDate)
        self.creationUTCOffset = try nestedContainer.decode(Int.self, forKey: .creationUTCOffset)
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
        var container: KeyedEncodingContainer<AllPossiblePayloadCodingKeys>

        if self.contents.additionalBodyParts.isEmpty {
            var encodingContainer = encoder.container(keyedBy: PayloadTypeCodingKeys.self)
            container = encodingContainer.nestedContainer(keyedBy: AllPossiblePayloadCodingKeys.self, forKey: self.contents.containerKey)
        } else {
            // For multipart requests, the outer container is left off.
            container = encoder.container(keyedBy: AllPossiblePayloadCodingKeys.self)
        }

        try container.encode(self.nonce, forKey: .nonce)
        try container.encode(self.creationDate, forKey: .creationDate)
        try container.encode(self.creationUTCOffset, forKey: .creationUTCOffset)

        try self.contents.encodeContents(to: &container)
    }

    var debugDescription: String {
        return "Payload(type: \(self.contents.containerKey.rawValue), nonce: \(self.nonce))"
    }
}

enum PayloadTypeCodingKeys: String, CodingKey {
    case response
    case event
    case person
    case device
    case appRelease = "app_release"
    case message
}

/// The union of coding keys from all payload types.
enum AllPossiblePayloadCodingKeys: String, CodingKey {
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

/// The contents of the payload.
///
/// Each payload type has an associated value corresponding to its content.
enum PayloadContents: Equatable {
    case surveyResponse(SurveyResponseContents)
    case event(EventContents)
    case person(PersonContents)
    case device(DeviceContents)
    case appRelease(AppReleaseContents)
    case message(MessageContents)

    var containerKey: PayloadTypeCodingKeys {
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

    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws {
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

    var additionalBodyParts: [HTTPBodyPart] {
        switch self {
        case .message(let messageContents):
            return messageContents.attachmentBodyParts

        default:
            return []
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
    func encodeContents(to container: inout KeyedEncodingContainer<AllPossiblePayloadCodingKeys>) throws
}

/// An empty object corresponding to the expected response when sending a payload.
struct PayloadResponse: Codable {}
