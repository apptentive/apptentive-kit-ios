//
//  EncryptionTests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 12/8/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import CommonCrypto
import XCTest

@testable import ApptentiveKit

class EncryptionTests: XCTestCase {

    func testKeyConversion() throws {
        let stringKey = "3F297DB62FD1402198FBD49F73ABC30A"
        let key = Data(hexString: stringKey)

        XCTAssertEqual(key?.count, 16)
        XCTAssertEqual(key?[0], 0x3F)
        XCTAssertEqual(key?[15], 0x0A)
    }

    func testEncryption() throws {
        let dataToEncrypt = "Encrypt me.".data(using: .utf8)!
        let key = Data(hexString: "3F297DB62FD1402198FBD49F73ABC30A")!
        let encryptedData = try dataToEncrypt.encrypted(with: key)

        let prefix = encryptedData.prefix(kCCBlockSizeAES128)
        let suffix = encryptedData.suffix(kCCBlockSizeAES128)

        XCTAssertNotNil(prefix)
        XCTAssertNotNil(suffix)

        let encryptedData2 = try dataToEncrypt.encrypted(with: key)

        let prefix2 = encryptedData2.prefix(kCCBlockSizeAES128)
        let suffix2 = encryptedData2.suffix(kCCBlockSizeAES128)

        XCTAssertNotEqual(prefix, prefix2, "Should have new initialization vector on each encryption operation.")
        XCTAssertNotEqual(suffix, suffix2, "Should have different encrypted data on each encryption operation.")
    }

    func testDecryption() throws {
        let dataToEncrypt = "Encrypt me.".data(using: .utf8)!
        let key = Data(hexString: "3F297DB62FD1402198FBD49F73ABC30A")!

        let encryptedData = try dataToEncrypt.encrypted(with: key)
        let decryptedData = try encryptedData.decrypted(with: key)

        XCTAssertEqual(dataToEncrypt, decryptedData)
    }
}
