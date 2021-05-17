//
//  FileRepository.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 11/21/19.
//  Copyright © 2019 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents a file in the filesystem and allows reading and writing encoded data to and from it.
class FileRepository<T> {
    let containerURL: URL
    let fileManager: FileManager
    let filename: String

    /// Whether the file this repository manages already exists on the filesystem.
    var fileExists: Bool {
        self.fileManager.fileExists(atPath: self.url.path)
    }

    /// Initializes a new file repository.
    /// - Parameters:
    ///   - containerURL: A file URL pointing to the parent directory for the file.
    ///   - filename: The name to use for the file.
    ///   - fileManager: The file manager object to use to access the filesystem.
    init(containerURL: URL, filename: String, fileManager: FileManager) {
        self.containerURL = containerURL
        self.filename = filename
        self.fileManager = fileManager
    }

    /// Loads and decodes the repository's file.
    /// - Throws: An error if the file can't be read or decoded.
    /// - Returns: The decoded object that was encoded in the file.
    func load() throws -> T {
        let data = try self.loadData()
        return try self.decode(data: data)
    }

    /// Encodes and saves the specified object to the repository's file.
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

    /// Loads the raw encoded data from the filesystem.
    /// - Throws: An error if the data could not be loaded.
    /// - Returns: The encoded data read from the filesystem.
    func loadData() throws -> Data {
        return try Data(contentsOf: self.url)
    }

    /// Saves the raw encoded data to the filesystem.
    /// - Parameter data: The data to be saved.
    /// - Throws: An error if the data could not be saved.
    fileprivate func save(data: Data) throws {
        try data.write(to: self.url)
    }

    /// Decodes encoded data into the desired object.
    /// - Parameter data: The data to be decoded.
    /// - Throws: An error if the data could not be decoded.
    /// - Returns: The decoded object.
    fileprivate func decode(data: Data) throws -> T {
        throw ApptentiveError.internalInconsistency
    }

    /// Encodes the object into data ready to be saved.
    /// - Parameter object: The object to encode.
    /// - Throws: An error if the object could not be encoded.
    /// - Returns: The encoded data.
    fileprivate func encode(object: T) throws -> Data {
        throw ApptentiveError.internalInconsistency
    }
}

/// A concrete subclass of `FileRepository` that saves data in Property List (plist) format.
class PropertyListRepository<T: Codable>: FileRepository<T> {
    let decoder = PropertyListDecoder()
    let encoder = PropertyListEncoder()

    override func decode(data: Data) throws -> T {
        return try self.decoder.decode(T.self, from: data)
    }

    override func encode(object: T) throws -> Data {
        return try self.encoder.encode(object)
    }

    override var fileExtension: String {
        return "plist"
    }
}
