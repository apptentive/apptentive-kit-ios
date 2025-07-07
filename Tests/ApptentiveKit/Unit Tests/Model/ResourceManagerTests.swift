//
//  ResourceManagerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 12/14/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation
import Testing

@testable import ApptentiveKit

struct ResourceManagerTests {
    var requestor: SpyRequestor
    var fileManager: MockFileManager
    var resourceManager: ResourceManager
    var containerURL: URL

    init() {
        self.requestor = SpyRequestor(temporaryURL: URL(fileURLWithPath: "/tmp/temp"))
        self.fileManager = MockFileManager()
        self.resourceManager = ResourceManager(fileManager: self.fileManager, requestor: self.requestor)
        self.containerURL = URL(fileURLWithPath: "/tmp/abc123")
    }

    @Test func testPrefetch() async throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        let prefetchURL = URL(string: "https://www.example.com/test")!
        let obsoleteRemoteURL = URL(string: "https://www.example.com/test2")!
        let obsoleteFileURL = self.containerURL.appendingPathComponent(ResourceManager.filename(for: obsoleteRemoteURL))
        try self.fileManager.writeData(prefetchData, to: obsoleteFileURL)

        #expect(self.fileManager.fileURLs.contains(obsoleteFileURL), "Should be a file named after expected filename")
        self.fileManager.contentsOfDirectory.append(obsoleteFileURL)

        await self.resourceManager.setPrefetchContainerURL(containerURL)

        await self.requestor.setResponseData(prefetchData)

        await self.resourceManager.prefetchResources(at: [prefetchURL])

        try await Task.sleep(nanoseconds: 1_000_000)

        let expectedURL = self.containerURL.appendingPathComponent(ResourceManager.filename(for: prefetchURL))

        #expect(!self.fileManager.fileURLs.contains(obsoleteFileURL), "Should not be a file named after deleted filename")
        #expect(self.fileManager.fileURLs.contains(expectedURL), "Should be a file named after expected filename")
        #expect(prefetchData == self.fileManager.data[expectedURL], "Prefetched data should match downloaded data")
    }

    @Test func testGetPrefetchedImage() async throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        let prefetchURL = URL(string: "https://www.example.com/test")!

        await self.resourceManager.setPrefetchContainerURL(containerURL)

        await self.requestor.setResponseData(prefetchData)

        await self.resourceManager.prefetchResources(at: [prefetchURL])

        let _ = try await self.resourceManager.getImage(at: prefetchURL, scale: 3)

    }

    @Test func testMultipleCompletionHandlers() async throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        await self.resourceManager.setPrefetchContainerURL(containerURL)

        let prefetchURL = URL(string: "https://www.example.com/test")!

        let _ = try await self.resourceManager.getImage(at: prefetchURL, scale: 3)

        let task = Task {
            try await self.resourceManager.getImage(at: prefetchURL, scale: 3)
        }

        let _ = try await task.value
    }

    @Test func testInvalidImage() async throws {
        let prefetchData = Data(base64Encoded: "aVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQAB")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        await self.resourceManager.setPrefetchContainerURL(containerURL)

        let prefetchURL = URL(string: "https://www.example.com/test")!

        await #expect {
            let _ = try await self.resourceManager.getImage(at: prefetchURL, scale: 3)
        } throws: { error in
            guard case ApptentiveError.resourceNotDecodableAsImage = error as! ApptentiveError else {
                return false
            }

            return true
        }
    }

    @Test func testDownloadError() async throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        await self.resourceManager.setPrefetchContainerURL(containerURL)

        let prefetchURL = URL(string: "https://www.example.com/test")!

        await self.requestor.setError(HTTPClientError.serverError(HTTPURLResponse(url: prefetchURL, mimeType: nil, expectedContentLength: 1, textEncodingName: nil), nil))

        await #expect {
            let _ = try await self.resourceManager.getImage(at: prefetchURL, scale: 3)
        } throws: { error in
            guard case HTTPClientError.serverError = error as! HTTPClientError else {
                return false
            }

            return true
        }
    }
}
