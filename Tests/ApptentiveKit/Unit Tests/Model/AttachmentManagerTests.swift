//
//  AttachmentManagerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 2/10/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Testing
import UIKit

@testable import ApptentiveKit

class AttachmentManagerTests {
    var spyRequestor = SpyRequestor(temporaryURL: URL(string: "https://www.example.com/")!)
    var attachmentManager: AttachmentManager!
    var fileManager = FileManager()
    var dogImageURL: URL!
    let tempDirectoryPath = "/tmp/\(UUID().uuidString)"
    var cacheURL: URL!

    init() throws {
        let savedURL = URL(fileURLWithPath: "\(tempDirectoryPath)/Application Support/com.apptentive.feedback/")
        self.cacheURL = URL(fileURLWithPath: "\(tempDirectoryPath)/Caches/com.apptentive.feedback/")

        try FileManager.default.createDirectory(at: savedURL, withIntermediateDirectories: true, attributes: [:])
        try FileManager.default.createDirectory(at: self.cacheURL, withIntermediateDirectories: true, attributes: [:])

        self.attachmentManager = AttachmentManager(requestor: self.spyRequestor, cacheContainerURL: self.cacheURL, savedContainerURL: savedURL)

        self.dogImageURL = URL(fileURLWithPath: "\(tempDirectoryPath)/#Dog.jpg")
        if !FileManager.default.fileExists(atPath: self.dogImageURL.path) {
            let dogURLInBundle = Bundle(for: BundleFinder.self).url(forResource: "dog", withExtension: "jpg", subdirectory: "Test Attachments")!
            try FileManager.default.copyItem(at: dogURLInBundle, to: self.dogImageURL)
        }
    }

    deinit {
        try! FileManager.default.removeItem(atPath: self.tempDirectoryPath)
    }

    @Test func testStoreData() async throws {
        let storedData = try Data(contentsOf: self.dogImageURL)
        let storedURL = try await self.attachmentManager.store(data: storedData, filename: "DogData.jpeg")

        #expect(FileManager.default.fileExists(atPath: storedURL.path))
        #expect(storedURL.lastPathComponent.hasSuffix("#DogData.jpeg"))
    }

    @Test func testStoreURL() async throws {
        let storedURL = try await self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        #expect(FileManager.default.fileExists(atPath: storedURL.path))
        #expect(storedURL.lastPathComponent.hasSuffix("#Dog.jpeg"))
    }

    @Test func testRemoveStorage() async throws {
        let storedURL = try await self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)

        try await self.attachmentManager.removeStorage(for: attachment)
        #expect(!FileManager.default.fileExists(atPath: storedURL.path))
    }

    @Test func testURLForAttachment() async throws {
        let storedURL = try await self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)

        #expect(self.attachmentManager.url(for: attachment) == storedURL)
    }

    @Test func testCacheFileExists() async throws {
        let remoteURL = URL(string: "https://www.example.com/dog.jpeg")!
        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .remote(remoteURL, size: 100), thumbnailData: nil)

        #expect(!self.attachmentManager.cacheFileExists(for: attachment, using: self.fileManager))

        let storedURL = try await self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        var attachment2 = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)

        #expect(self.attachmentManager.cacheFileExists(for: attachment2, using: self.fileManager))

        attachment2.storage = try await self.attachmentManager.cacheQueuedAttachment(attachment2)

        #expect(self.attachmentManager.cacheFileExists(for: attachment2, using: self.fileManager))
    }

    @Test func testCacheQueuedAttachment() async throws {
        let storedURL = try await self.attachmentManager.store(url: self.dogImageURL, filename: "Dog.jpeg")

        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .saved(path: storedURL.lastPathComponent), thumbnailData: nil)
        let storage = try await self.attachmentManager.cacheQueuedAttachment(attachment)
        guard case .cached(let path) = storage else {
            throw TestError(reason: "Expecting cached file to have cache storage")
        }

        #expect(FileManager.default.fileExists(atPath: URL(fileURLWithPath: path, relativeTo: self.cacheURL).path))
    }

    @Test func testDownload() async throws {
        await self.spyRequestor.setTemporaryURL(self.dogImageURL)
        let remoteURL = URL(string: "https://www.example.com/dog.jpeg")!
        let attachment = MessageList.Message.Attachment(contentType: "image/jpeg", filename: "Dog.jpeg", storage: .remote(remoteURL, size: 100), thumbnailData: nil)
        let localURL = try await self.attachmentManager.download(attachment)
        #expect(FileManager.default.fileExists(atPath: localURL.path))
    }

    @Test func testFriendlyFilename() throws {
        let url = URL(fileURLWithPath: "/tmp/833723D0-B135-43DE-A521-A0EB1987A3EA#Attachment 1.jpeg")
        #expect(AttachmentManager.friendlyFilename(for: url) == "Attachment 1.jpeg")

        let url2 = URL(fileURLWithPath: "/tmp/833723D0-B135-43DE-A521-A0EB1987A3EA#Attachment #1.jpeg")
        #expect(AttachmentManager.friendlyFilename(for: url2) == "Attachment #1.jpeg")
    }

    @Test func testMediaType() throws {
        #expect(AttachmentManager.mediaType(for: "Attachment 1.jpeg") == "image/jpeg")
        #expect(AttachmentManager.mediaType(for: "Attachment 2.png") == "image/png")
        #expect(AttachmentManager.mediaType(for: "Attachment 3.foo") == "application/octet-stream")
        #expect(AttachmentManager.mediaType(for: "Attachment 4") == "application/octet-stream")
    }

    @Test func testPathExtension() throws {
        #expect(AttachmentManager.pathExtension(for: "image/jpeg") == "jpeg")
        #expect(AttachmentManager.pathExtension(for: "image/png") == "png")
        #expect(AttachmentManager.pathExtension(for: "application/octet-stream") == nil)
    }

    // This causes random test failures in other tests. Leaving this out of unit tests for now.
    //    @Test func testCreateThumbnail() throws {
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
