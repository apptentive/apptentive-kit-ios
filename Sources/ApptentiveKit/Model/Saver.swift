//
//  Saver.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/21/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents a file in the filesystem and allows writing encoded data to it.
class Saver<T> {
    let containerURL: URL
    let fileManager: FileManager
    let filename: String

    /// Initializes a new saver.
    /// - Parameters:
    ///   - containerURL: A file URL pointing to the parent directory for the file.
    ///   - filename: The name to use for the file.
    ///   - fileManager: The file manager object to use to access the filesystem.
    init(containerURL: URL, filename: String, fileManager: FileManager) {
        self.containerURL = containerURL
        self.filename = filename
        self.fileManager = fileManager
    }

    /// Encodes and saves the specified object to the saver's file.
    /// - Parameter object: The object to encode and save.
    /// - Throws: An error if the object can't be encoded or saved.
    func save(_ object: T) throws {
        let data = try self.encode(object: object)
        try self.save(data: data)
    }

    /// The file URL at which the file is/will be saved.
    fileprivate var url: URL {
        containerURL.appendingPathComponent(self.filename).appendingPathExtension(self.fileExtension)
    }

    /// The extension to add to the filename when saving the file.
    var fileExtension: String {
        ""
    }

    /// Saves the raw encoded data to the filesystem.
    /// - Parameter data: The data to be saved.
    /// - Throws: An error if the data could not be saved.
    fileprivate func save(data: Data) throws {
        try data.write(to: self.url, options: [.atomic])
    }

    /// Encodes the object into data ready to be saved.
    /// - Parameter object: The object to encode.
    /// - Throws: An error if the object could not be encoded.
    /// - Returns: The encoded data.
    fileprivate func encode(object: T) throws -> Data {
        throw ApptentiveError.internalInconsistency
    }
}

/// A concrete subclass of `Saver` that saves data in Property List (plist) format.
class PropertyListSaver<T: Codable>: Saver<T> {
    let decoder = PropertyListDecoder()
    let encoder = PropertyListEncoder()

    override func encode(object: T) throws -> Data {
        return try self.encoder.encode(object)
    }

    override var fileExtension: String {
        return "plist"
    }
}

/// A concrete subclass of `Saver` that saves data in Property List (plist) format.
final class EncryptedPropertyListSaver<T: Codable>: PropertyListSaver<T> {
    var encryptionKey: Data?

    init(containerURL: URL, filename: String, fileManager: FileManager, encryptionKey: Data?) {
        self.encryptionKey = encryptionKey

        super.init(containerURL: containerURL, filename: filename, fileManager: fileManager)
    }

    override func encode(object: T) throws -> Data {
        let plaintext = try self.encoder.encode(object)

        if let encryptionKey = self.encryptionKey {
            return try plaintext.encrypted(with: encryptionKey)
        } else {
            return plaintext
        }
    }

    override var fileExtension: String {
        if let _ = self.encryptionKey {
            return "\(super.fileExtension).encrypted"
        } else {
            return super.fileExtension
        }
    }
}
