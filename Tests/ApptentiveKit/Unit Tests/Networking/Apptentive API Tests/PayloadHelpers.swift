//
//  PayloadHelpers.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/21/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import GenericJSON
import Testing

@testable import ApptentiveKit

func checkPayloadEquivalence(between bodyData: Data, and expectedJSON: String, comparisons: [String], shouldOpenContainer: Bool = true) throws {
    var actualJSON = try JSON(JSONSerialization.jsonObject(with: bodyData))
    var expectedJSON = try JSON(JSONSerialization.jsonObject(with: expectedJSON.data(using: .utf8)!))

    if shouldOpenContainer {
        let containerName = actualJSON.objectValue?.keys.first(where: { $0 != "token" })
        actualJSON = actualJSON[containerName!]!
        expectedJSON = expectedJSON[containerName!]!
    }

    #expect(actualJSON["nonce"] != nil)
    #expect(expectedJSON["nonce"] != nil)

    #expect(Date(timeIntervalSinceReferenceDate: actualJSON["client_created_at"]!.doubleValue!) > Date(timeIntervalSince1970: 1_600_904_569))
    #expect(Date(timeIntervalSince1970: expectedJSON["client_created_at"]!.doubleValue!) == Date(timeIntervalSince1970: 1_600_904_569))

    #expect(actualJSON["client_created_at_utc_offset"] != nil)
    #expect(expectedJSON["client_created_at_utc_offset"] != nil)

    for comparison in comparisons {
        #expect(actualJSON[comparison] == expectedJSON[comparison])
    }
}

func checkRequestHeading(for payload: Payload, decoder: JSONDecoder, expectedMethod: HTTPMethod, expectedPathSuffix: String) throws {
    let credentials = PayloadAPICredentials(appCredentials: .init(key: "abc", signature: "123"), payloadCredentials: .header(id: "def", token: "456"))

    let request = PayloadRequest(payload: payload, credentials: credentials, decoder: decoder)
    let headers = try request.headers(userAgent: "Apptentive/1.2.3 (Apple)", languageCode: "de")

    let expectedHeaders = [
        "APPTENTIVE-KEY": "abc",
        "APPTENTIVE-SIGNATURE": "123",
        "X-API-Version": "15",
        "User-Agent": "Apptentive/1.2.3 (Apple)",
        "Content-Type": payload.contentType,
        "Authorization": "Bearer 456",
        "Accept": "application/json;charset=UTF-8",
        "Accept-Charset": "UTF-8",
        "Accept-Language": "de",
    ]

    #expect(headers == expectedHeaders)

    let url = try request.url(relativeTo: URL(string: "https://api.apptentive.com/")!)

    #expect(url.path == "/conversations/def/\(expectedPathSuffix)")

    #expect(request.method == expectedMethod)
}

func checkEncryptedPayloadEquivalence(between bodyData: Data, and expectedJSON: String, comparisons: [String], encryptionKey: Data) throws {
    let decryptedBodyData = try bodyData.decrypted(with: encryptionKey)
    var actualJSON = try JSON(JSONSerialization.jsonObject(with: decryptedBodyData))
    var expectedJSON = try JSON(JSONSerialization.jsonObject(with: expectedJSON.data(using: .utf8)!))

    #expect(actualJSON["token"] != nil)

    let containerName = actualJSON.objectValue?.keys.first(where: { $0 != "token" })
    actualJSON = actualJSON[containerName!]!
    expectedJSON = expectedJSON[containerName!]!

    #expect(actualJSON["nonce"] != nil)
    #expect(expectedJSON["nonce"] != nil)

    #expect(Date(timeIntervalSinceReferenceDate: actualJSON["client_created_at"]!.doubleValue!) > Date(timeIntervalSince1970: 1_600_904_569))
    #expect(Date(timeIntervalSince1970: expectedJSON["client_created_at"]!.doubleValue!) == Date(timeIntervalSince1970: 1_600_904_569))

    #expect(actualJSON["client_created_at_utc_offset"] != nil)
    #expect(expectedJSON["client_created_at_utc_offset"] != nil)

    for comparison in comparisons {
        #expect(actualJSON[comparison] == expectedJSON[comparison])
    }
}

func checkEncryptedRequestHeading(for payload: Payload, decoder: JSONDecoder, expectedMethod: HTTPMethod, expectedPathSuffix: String) throws {
    let credentials = PayloadAPICredentials(appCredentials: .init(key: "abc", signature: "123"), payloadCredentials: .embedded(id: "def"))
    let request = PayloadRequest(payload: payload, credentials: credentials, decoder: decoder)
    let headers = try request.headers(userAgent: "Apptentive/1.2.3 (Apple)", languageCode: "de")

    let expectedHeaders = [
        "APPTENTIVE-KEY": "abc",
        "APPTENTIVE-SIGNATURE": "123",
        "APPTENTIVE-ENCRYPTED": "true",
        "X-API-Version": "15",
        "User-Agent": "Apptentive/1.2.3 (Apple)",
        "Content-Type": payload.contentType,
        "Accept": "application/json;charset=UTF-8",
        "Accept-Charset": "UTF-8",
        "Accept-Language": "de",
    ]

    #expect(headers == expectedHeaders)

    let url = try request.url(relativeTo: URL(string: "https://api.apptentive.com/")!)

    #expect(url.path == "/conversations/def/\(expectedPathSuffix)")

    #expect(request.method == expectedMethod)
}
