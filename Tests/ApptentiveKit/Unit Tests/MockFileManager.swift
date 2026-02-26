//
//  SpyFileManager.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 12/15/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation

@testable import ApptentiveKit

final class MockFileManager: FileManaging, @unchecked Sendable {
    var directoryURLs = Set<URL>()
    var fileURLs = Set<URL>()
    var data = [URL: Data]()
    var contentsOfDirectory = [URL]()  // Note: not mocked

    var directoryCreationError: Error?
    var itemRemovalError: Error?
    var itemMoveError: Error?
    var itemCopyError: Error?
    var readError: Error?
    var writeError: Error?
    var contentsOfDirectoryError: Error?

    func fileExists(at url: URL) -> Bool {
        return self.fileURLs.contains(url)
    }

    func createDirectory(at url: URL) throws {
        if let directoryCreationError = self.directoryCreationError {
            throw directoryCreationError
        } else {
            self.directoryURLs.insert(url)
        }
    }

    func removeItem(at url: URL) throws {
        if let itemRemovalError = self.itemRemovalError {
            throw itemRemovalError
        } else {
            self.directoryURLs.remove(url)
            self.fileURLs.remove(url)
        }
    }

    func fileExists(at url: URL, isDirectory: inout Bool) -> Bool {
        if fileURLs.contains(url) {
            isDirectory = false
            return true
        } else if directoryURLs.contains(url) {
            isDirectory = true
            return true
        } else {
            return false
        }
    }

    func moveItem(at fromURL: URL, to toURL: URL) throws {
        if let itemMoveError = self.itemMoveError {
            throw itemMoveError
        } else if fileURLs.contains(fromURL) {
            fileURLs.remove(fromURL)
            fileURLs.insert(toURL)
            self.data[toURL] = self.data[fromURL]
            self.data[fromURL] = nil
        } else if directoryURLs.contains(fromURL) {
            directoryURLs.remove(fromURL)
            directoryURLs.insert(toURL)
        } else {
            throw MockFileManagerError.urlNotFound
        }
    }

    func contentsOfDirectory(at: URL) throws -> [URL] {
        if let contentsOfDirectoryError = self.contentsOfDirectoryError {
            throw contentsOfDirectoryError
        } else {
            return self.contentsOfDirectory
        }
    }

    func copyItem(at fromURL: URL, to toURL: URL) throws {
        if let itemCopyError = self.itemCopyError {
            throw itemCopyError
        } else if fileExists(at: fromURL) {
            fileURLs.insert(toURL)
            data[toURL] = data[fromURL]
        } else {
            throw MockFileManagerError.urlNotFound
        }
    }

    func writeData(_ data: Data, to url: URL) throws {
        if let writeError = self.writeError {
            throw writeError
        } else {
            self.data[url] = data
            self.fileURLs.insert(url)
        }
    }

    func readData(from url: URL) throws -> Data {
        if let readError = self.readError {
            throw readError
        } else if let data = self.data[url] {
            return data
        } else {
            throw MockFileManagerError.urlNotFound
        }
    }
}

enum MockFileManagerError: Swift.Error {
    case urlNotFound
}
