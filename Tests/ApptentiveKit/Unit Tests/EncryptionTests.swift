//
//  EncryptionTests.swift
//  ApptentiveUnitTests
//
//  Created by Luqmaan Khan on 12/8/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import CommonCrypto
import Foundation
import Testing

@testable import ApptentiveKit

struct EncryptionTests {

    @Test func testKeyConversion() throws {
        let stringKey = "3F297DB62FD1402198FBD49F73ABC30A"
        let key = Data(hexString: stringKey)

        #expect(key?.count == 16)
        #expect(key?[0] == 0x3F)
        #expect(key?[15] == 0x0A)
    }

    @Test func testEncryption() throws {
        let dataToEncrypt = "Encrypt me.".data(using: .utf8)!
        let key = Data(hexString: "3F297DB62FD1402198FBD49F73ABC30A")!
        let encryptedData = try dataToEncrypt.encrypted(with: key)

        let prefix = encryptedData.prefix(kCCBlockSizeAES128)
        let suffix = encryptedData.suffix(kCCBlockSizeAES128)

        let encryptedData2 = try dataToEncrypt.encrypted(with: key)

        let prefix2 = encryptedData2.prefix(kCCBlockSizeAES128)
        let suffix2 = encryptedData2.suffix(kCCBlockSizeAES128)

        #expect(prefix != prefix2, "Should have new initialization vector on each encryption operation.")
        #expect(suffix != suffix2, "Should have different encrypted data on each encryption operation.")
    }

    @Test func testDecryption() throws {
        let dataToEncrypt = "Encrypt me.".data(using: .utf8)!
        let key = Data(hexString: "3F297DB62FD1402198FBD49F73ABC30A")!

        let encryptedData = try dataToEncrypt.encrypted(with: key)
        let decryptedData = try encryptedData.decrypted(with: key)

        #expect(dataToEncrypt == decryptedData)
    }
}
