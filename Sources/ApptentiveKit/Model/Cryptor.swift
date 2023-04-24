//
//  Cryptor.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/12/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import CommonCrypto
import Foundation

struct Cryptor {
    let algorithm: Int
    let options: Int
    let initializationVectorSize: Int

    func encrypt(_ data: Data, using key: Data) throws -> Data {
        let initializationVector = try self.secureRandomData(ofSize: self.initializationVectorSize)
        let encryptedData = try self.perform(kCCEncrypt, on: data, using: key, initializationVector: initializationVector)

        return initializationVector + encryptedData
    }

    func decrypt(_ data: Data, using key: Data) throws -> Data {
        let initializationVector = data.prefix(self.initializationVectorSize)  // Initialization vector is prepended.
        let encryptedData = data.suffix(from: self.initializationVectorSize)  // Rest of self is encrypted data.

        return try self.perform(kCCDecrypt, on: encryptedData, using: key, initializationVector: initializationVector)
    }

    /// Generates secure random data of the specified size.
    /// - Parameter size: The number of bytes of random data to generate.
    /// - Throws: An error that describes how the operation failed.
    /// - Returns: The newly-generated initialization vector.
    private func secureRandomData(ofSize size: Int) throws -> Data {
        let bytes = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: 1)
        defer {
            bytes.deallocate()
        }

        let status = CCRandomGenerateBytes(bytes, size)

        guard status == kCCSuccess else {
            throw CryptorError.initializationVectorFailure(status)
        }

        return Data(bytes: bytes, count: size)
    }

    /// Unwraps the bytes inside of the input data, key, and initialization vector and performs the specified operation.
    /// - Parameters:
    ///   - operation: The operation to perform (encryption or decryption).
    ///   - data: The input data.
    ///   - key: The key used to encrypt/decrypt the data.
    ///   - initializationVector: The initialization vector used to encrypt/decrypt the data.
    /// - Throws: An error that describes how the operation failed.
    /// - Returns: The encrypted or decrypted data.
    private func perform(_ operation: Int, on data: Data, using key: Data, initializationVector: Data) throws -> Data {
        try key.withUnsafeBytes { keyBytes in
            try data.withUnsafeBytes { dataBytes in
                try initializationVector.withUnsafeBytes { ivBytes in
                    let resultSize: Int = data.count + kCCBlockSizeAES128 * 2

                    let result = UnsafeMutableRawPointer.allocate(
                        byteCount: resultSize,
                        alignment: 1)

                    defer { result.deallocate() }

                    var resultMoved: Int = 0

                    let status =
                        CCCrypt(
                            CCOperation(operation),
                            CCAlgorithm(self.algorithm),
                            CCOptions(self.options),
                            keyBytes.baseAddress,
                            key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress,
                            data.count,
                            result,
                            resultSize,
                            &resultMoved)

                    guard status == kCCSuccess else {
                        throw CryptorError.commonCryptoFailure(status)
                    }

                    return Data(bytes: result, count: resultMoved)
                }
            }
        }
    }
}

enum CryptorError: Swift.Error, CustomStringConvertible {
    case initializationVectorFailure(CCRNGStatus)
    case commonCryptoFailure(CCCryptorStatus)

    // swift-format-ignore
    public var description: String {
        switch self {
        case .initializationVectorFailure(let rngStatus):
            return "Failure creating random data: \(Self.description(for: rngStatus))."

        case .commonCryptoFailure(let cryptorStatus):
            return "Failure performing CommonCrypto operation: \(Self.description(for: cryptorStatus))."
        }
    }

    private static func description(for status: Int32) -> String {
        switch Int(status) {
        case kCCParamError:
            return "Illegal parameter value."

        case kCCBufferTooSmall:
            return "Insufficent buffer provided for specified operation."

        case kCCMemoryFailure:
            return "Memory allocation failure"

        case kCCAlignmentError:
            return "Input size was not aligned properly"

        case kCCDecodeError:
            return "Input data did not decode or decrypt properly"

        case kCCUnimplemented:
            return "Function not implemented for the current algorithm"

        case kCCOverflow:
            return "Overflow"

        case kCCRNGFailure:
            return "Random number generator failure"

        case kCCUnspecifiedError:
            return "Unspecified error"

        case kCCCallSequenceError:
            return "Call sequence error"

        case kCCKeySizeError:
            return "Key size error"

        case kCCInvalidKey:
            return "Key is not valid"

        default:
            return "Unknown"
        }
    }
}
