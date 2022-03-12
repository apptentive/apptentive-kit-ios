//
//  AttachmentManagerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/10/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit
import XCTest

@testable import ApptentiveKit

class AttachmentManagerTests: XCTestCase {
    var spyRequestor = SpyRequestor(temporaryURL: URL(string: "https://www.example.com/")!)
    var attachmentManager: AttachmentManager!
    var dogImageURL: URL!
    let tempDirectoryPath = "/tmp/\(UUID().uuidString)"
    var cacheURL: URL!

    override func setUpWithError() throws {
        let savedURL = URL(fileURLWithPath: "\(tempDirectoryPath)/Application Support/com.apptentive.feedback/")
        self.cacheURL = URL(fileURLWithPath: "\(tempDirectoryPath)/Caches/com.apptentive.feedback/")

        try FileManager.default.createDirectory(at: savedURL, withIntermediateDirectories: true, attributes: [:])
        try FileManager.default.createDirectory(at: self.cacheURL, withIntermediateDirectories: true, attributes: [:])

        self.attachmentManager = AttachmentManager(fileManager: .default, requestor: self.spyRequestor, cacheContainerURL: self.cacheURL, savedContainerURL: savedURL)

        self.dogImageURL = URL(fileURLWithPath: "\(tempDirectoryPath)/#Dog.jpg")
        if !FileManager.default.fileExists(atPath: self.dogImageURL.path) {
            let dogURLInBundle = Bundle(for: type(of: self)).url(forResource: "dog", withExtension: "jpg", subdirectory: "Test Attachments")!
            try FileManager.default.copyItem(at: dogURLInBundle, to: self.dogImageURL)
        }

        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(atPath: self.tempDirectoryPath)

        try super.tearDownWithError()
    }

    func testStoreData() throws {
        let storedData = try Data(contentsOf: self.dogImageURL)
        let storedURL = try self.attachmentManager.store(data: storedData, filename: "DogData.jpeg")

        XCTAssert(FileManager.default.fileExists(atPath: storedURL.path))
        XCTAssert(storedURL.lastPathComponent.hasSuffix("#DogData.jpeg"))
    }

    func testStoreURL() throws {
        let storedURL = try self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        XCTAssert(FileManager.default.fileExists(atPath: storedURL.path))
        XCTAssert(storedURL.lastPathComponent.hasSuffix("#Dog.jpeg"))
    }

    func testRemoveStorage() throws {
        let storedURL = try self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)

        try self.attachmentManager.removeStorage(for: attachment)
        XCTAssertFalse(FileManager.default.fileExists(atPath: storedURL.path))
    }

    func testURLForAttachment() throws {
        let storedURL = try self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)

        XCTAssertEqual(self.attachmentManager.url(for: attachment), storedURL)
    }

    func testCacheFileExists() throws {
        let remoteURL = URL(string: "https://www.example.com/dog.jpeg")!
        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .remote(remoteURL, size: 100), thumbnailData: nil)

        XCTAssertFalse(self.attachmentManager.cacheFileExists(for: attachment))

        let storedURL = try self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        var attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)

        XCTAssert(self.attachmentManager.cacheFileExists(for: attachment2))

        attachment2.storage = try self.attachmentManager.cacheQueuedAttachment(attachment2)

        XCTAssert(self.attachmentManager.cacheFileExists(for: attachment2))
    }

    func testCacheQueuedAttachment() throws {
        let storedURL = try self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)
        let storage = try self.attachmentManager.cacheQueuedAttachment(attachment)
        guard case .cached(let path) = storage else {
            return XCTFail("Expecting cached file to have cache storage")
        }

        XCTAssert(FileManager.default.fileExists(atPath: URL(fileURLWithPath: path, relativeTo: self.cacheURL).path))
    }

    func testDownload() throws {
        self.spyRequestor.temporaryURL = self.dogImageURL
        let remoteURL = URL(string: "https://www.example.com/dog.jpeg")!
        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .remote(remoteURL, size: 100), thumbnailData: nil)

        let expectation = self.expectation(description: "thumbnail")

        self.attachmentManager.download(attachment) { result in
            switch result {
            case .success(let localURL):
                XCTAssert(FileManager.default.fileExists(atPath: localURL.path))

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }

            expectation.fulfill()
        } progress: { _ in
            // Not tested here
        }

        self.wait(for: [expectation], timeout: 1)
    }

    func testFriendlyFilename() throws {
        let url = URL(fileURLWithPath: "/tmp/833723D0-B135-43DE-A521-A0EB1987A3EA#Attachment 1.jpeg")
        XCTAssertEqual(AttachmentManager.friendlyFilename(for: url), "Attachment 1.jpeg")

        let url2 = URL(fileURLWithPath: "/tmp/833723D0-B135-43DE-A521-A0EB1987A3EA#Attachment #1.jpeg")
        XCTAssertEqual(AttachmentManager.friendlyFilename(for: url2), "Attachment #1.jpeg")
    }

    func testMediaType() throws {
        XCTAssertEqual(AttachmentManager.mediaType(for: "Attachment 1.jpeg"), "image/jpeg")
        XCTAssertEqual(AttachmentManager.mediaType(for: "Attachment 2.png"), "image/png")
        XCTAssertEqual(AttachmentManager.mediaType(for: "Attachment 3.foo"), "application/octet-stream")
        XCTAssertEqual(AttachmentManager.mediaType(for: "Attachment 4"), "application/octet-stream")
    }

    func testPathExtension() throws {
        XCTAssertEqual(AttachmentManager.pathExtension(for: "image/jpeg"), "jpeg")
        XCTAssertEqual(AttachmentManager.pathExtension(for: "image/png"), "png")
        XCTAssertEqual(AttachmentManager.pathExtension(for: "application/octet-stream"), nil)
    }

    // This causes random test failures in other tests. Leaving this out of unit tests for now.
    //    func testCreateThumbnail() throws {
    //        let expectation = self.expectation(description: "thumbnail")
    //        expectation.assertForOverFulfill = false
    //
    //        AttachmentManager.createThumbnail(of: CGSize(width: 44, height: 44), for: self.dogImageURL) { result in
    //            switch result {
    //            case .success(let image):
    //                XCTAssertEqual(image.size, CGSize(width: 34, height: 44))
    //
    //            case .failure(let error):
    //                XCTFail(error.localizedDescription)
    //            }
    //
    //            expectation.fulfill()
    //            }
    //        }
    //
    //        self.wait(for: [expectation], timeout: 1.0)
    //    }
}
