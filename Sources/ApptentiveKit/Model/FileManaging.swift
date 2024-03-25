//
//  FileManaging.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 12/15/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol FileManaging {
    func fileExists(at: URL) -> Bool
    func createDirectory(at: URL) throws
    func removeItem(at: URL) throws
    func fileExists(at url: URL, isDirectory: inout Bool) -> Bool
    func moveItem(at: URL, to: URL) throws
    func contentsOfDirectory(at: URL) throws -> [URL]
    func copyItem(at: URL, to: URL) throws
    func writeData(_ data: Data, to url: URL) throws
    func readData(from url: URL) throws -> Data
}

extension FileManager: FileManaging {
    func writeData(_ data: Data, to url: URL) throws {
        try data.write(to: url)
    }

    func readData(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

    func createDirectory(at url: URL) throws {
        try self.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try self.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }

    func fileExists(at url: URL) -> Bool {
        self.fileExists(atPath: url.path)
    }

    func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
        var isDirectoryRaw: ObjCBool = false

        let exists = self.fileExists(atPath: url.path, isDirectory: &isDirectoryRaw)

        isDirectory = isDirectoryRaw.boolValue

        return exists
    }
}
