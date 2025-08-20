//
//  SecureTokenStore.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/21/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

import Foundation
import Security

protocol SecureTokenStoring {
    func saveToken(_ token: String, with id: String) throws
    func getToken(withID id: String) throws -> String
}

class SecureTokenStore: SecureTokenStoring {

    private static let service = "com.apptentive"

    /// Saves a JWT to the keychain with a specific identifier.
    /// - Parameters:
    ///   - token: The JWT string to save.
    ///   - id: Unique identifier for this JWT.
    /// - Throws: An error if saving the JWT failed.
    func saveToken(_ token: String, with id: String) throws {
        guard let data = token.data(using: .utf8) else {
            throw TokenStoringError.tokenNotConvertibleToData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: id,
            kSecValueData as String: data,
        ]

        // Delete any existing item first
        SecItemDelete(query as CFDictionary)

        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            // TODO: better error
            throw ApptentiveError.internalInconsistency
        }
    }

    /// Retrieves a JWT from the keychain by ID.
    /// - Parameter id: The identifier for the JWT.
    /// - Returns: The JWT string if found, nil otherwise.
    /// - Throws: An error if the JWT retrieval fails.
    func getToken(withID id: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: id,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
            let data = result as? Data,
            let jwt = String(data: data, encoding: .utf8)
        {
            return jwt
        } else {
            throw TokenStoringError.unhandledError(status: status)
        }
    }
}

enum TokenStoringError: Swift.Error {
    case unhandledError(status: OSStatus)
    case tokenNotConvertibleToData
}
