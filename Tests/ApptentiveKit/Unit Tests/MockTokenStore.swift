//
//  MockTokenStore.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/23/25.
//  Copyright © 2025 Apptentive, Inc. All rights reserved.
//

@testable import ApptentiveKit

class MockTokenStore: SecureTokenStoring {
    var tokenStorage = [String: String]()

    func saveToken(_ token: String, with id: String) throws {
        self.tokenStorage[id] = token
    }

    func getToken(withID id: String) throws -> String {
        guard let token = self.tokenStorage[id] else {
            throw TokenStoringError.unhandledError(status: -1)
        }

        return token
    }
}
