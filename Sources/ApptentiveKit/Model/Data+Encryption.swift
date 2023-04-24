//
//  Data+ApptentiveEncryption.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 12/7/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import CommonCrypto
import Foundation

extension Cryptor {
    static let apptentive: Self = .init(algorithm: kCCAlgorithmAES128, options: kCCOptionPKCS7Padding, initializationVectorSize: kCCKeySizeAES128)
}

extension Data {
    /// Ecrypts the data using the kCCAlgorithmAES128 algorithm.
    /// - Parameter key: The encryption key (must be of kCCKeySizeAES256 size).
    /// - Throws: An error that describes how the encryption operation failed.
    /// - Returns: The encrypted data.
    func encrypted(with key: Data) throws -> Data {
        return try Cryptor.apptentive.encrypt(self, using: key)
    }

    /// Decrypts the data.
    /// - Parameter key: The decryption key which must be of kCCKeySizeAES256 size.
    /// - Throws: An error that describes how the decryption operation failed.
    /// - Returns: The decrypted data.
    func decrypted(with key: Data) throws -> Data {
        return try Cryptor.apptentive.decrypt(self, using: key)
    }

    /// Creates a new Data object by converting hexadecimal characters in the input string.
    ///
    /// Returns nil if the string contains non-hexadecimal characters or has an odd number of characters.
    /// - Parameter hexString: A string of hexadecimal characters.
    init?(hexString: String) {
        // TODO: Use `Scanner` when we drop iOS <13 support.
        var result = Data()
        var index = hexString.startIndex

        while index < hexString.endIndex {
            guard let endIndex = hexString.index(index, offsetBy: 2, limitedBy: hexString.endIndex) else {
                return nil
            }

            guard let byte = UInt8(String(hexString[index..<endIndex]), radix: 16) else {
                return nil
            }

            result.append(byte)

            index = endIndex
        }

        self = result
    }

    var hexString: String {
        self.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
