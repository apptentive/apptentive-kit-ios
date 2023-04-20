//
//  JWT.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 2/16/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

struct JWT {
    let header: Header
    let payload: Payload

    init(string: String) throws {
        let stringComponents = string.components(separatedBy: ".")
        let components = stringComponents.compactMap {
            Self.unURLifyBase64String($0)
        }.compactMap {
            Data(base64Encoded: $0)
        }

        guard components.count == 3 else {
            throw JWTError.invalidJWTString
        }

        self.header = try JSONDecoder.apptentive.decode(Header.self, from: components[0])
        self.payload = try JSONDecoder.apptentive.decode(Payload.self, from: components[1])
    }

    struct Header: Decodable {
        let algorithm: Algorithm
        let type: `Type`

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            let typeCode = try container.decode(String.self, forKey: .type)
            let algorithmCode = try container.decode(String.self, forKey: .algorithm)

            guard let type = `Type`(rawValue: typeCode) else {
                throw JWTError.unsupportedTokenType
            }

            guard let algorithm = Algorithm(rawValue: algorithmCode) else {
                throw JWTError.unsupportedAlgorithm
            }

            self.type = type
            self.algorithm = algorithm
        }

        enum CodingKeys: String, CodingKey {
            case algorithm = "alg"
            case type = "typ"
        }

        enum Algorithm: String {
            case hmacSHA256 = "HS256"
            case hmacSHA512 = "HS512"
        }

        enum `Type`: String {
            case jwt = "JWT"
        }
    }

    struct Payload: Decodable {
        let issuer: String?
        let expiry: Date?
        let subject: String?
        let audience: String?
        let notBefore: Date?
        let issuedAt: Date?
        let jwtID: String?
        let otherClaims: [String: Any]

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: StandardClaimKeys.self)

            self.issuer = try container.decodeIfPresent(String.self, forKey: JWT.Payload.StandardClaimKeys.issuer)
            self.expiry = try container.decodeIfPresent(Date.self, forKey: JWT.Payload.StandardClaimKeys.expiry)
            self.subject = try container.decodeIfPresent(String.self, forKey: JWT.Payload.StandardClaimKeys.subject)
            self.audience = try container.decodeIfPresent(String.self, forKey: JWT.Payload.StandardClaimKeys.audience)
            self.notBefore = try container.decodeIfPresent(Date.self, forKey: JWT.Payload.StandardClaimKeys.notBefore)
            self.issuedAt = try container.decodeIfPresent(Date.self, forKey: JWT.Payload.StandardClaimKeys.issuedAt)
            self.jwtID = try container.decodeIfPresent(String.self, forKey: JWT.Payload.StandardClaimKeys.jwtID)

            let standardClaimKeys = StandardClaimKeys.allCases.map(\.rawValue)

            var otherClaims = [String: Any]()
            let otherClaimDecoder = try decoder.container(keyedBy: OtherClaimKeys.self)

            for key in otherClaimDecoder.allKeys {
                guard !standardClaimKeys.contains(key.stringValue) else {
                    continue
                }

                if let stringValue = try? otherClaimDecoder.decode(String.self, forKey: key) {
                    otherClaims[key.stringValue] = stringValue
                } else if let boolValue = try? otherClaimDecoder.decode(Bool.self, forKey: key) {
                    otherClaims[key.stringValue] = boolValue
                } else if let intValue = try? otherClaimDecoder.decode(Int.self, forKey: key) {
                    otherClaims[key.stringValue] = intValue
                } else if let doubleValue = try? otherClaimDecoder.decode(Double.self, forKey: key) {
                    otherClaims[key.stringValue] = doubleValue
                }
            }

            self.otherClaims = otherClaims
        }

        subscript(key: String) -> Any? {
            get {
                return self.otherClaims[key]
            }
        }

        enum StandardClaimKeys: String, CodingKey, CaseIterable {
            case issuer = "iss"
            case expiry = "exp"
            case subject = "sub"
            case audience = "aud"
            case notBefore = "nbf"
            case issuedAt = "iat"
            case jwtID = "jti"
        }

        struct OtherClaimKeys: CodingKey {
            var stringValue: String

            init?(stringValue: String) {
                self.stringValue = stringValue
            }

            var intValue: Int? = nil

            init?(intValue: Int) {
                return nil
            }

            static func key(for string: String) throws -> Self {
                guard let key = OtherClaimKeys(stringValue: string) else {
                    throw JWTError.internalInconsistency
                }

                return key
            }
        }
    }

    private static func unURLifyBase64String(_ input: String) -> String {
        let result = input.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let padding = result.count % 4

        return result.appending(String(repeating: "=", count: padding))
    }
}

enum JWTError: Swift.Error {
    case invalidJWTString
    case unsupportedTokenType
    case unsupportedAlgorithm
    case internalInconsistency
}
