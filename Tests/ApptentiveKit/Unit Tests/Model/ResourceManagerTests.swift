//
//  ResourceManagerTests.swift
//  ApptentiveUnitTests
//
//  Created by Frank Schmitt on 12/14/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import XCTest

@testable import ApptentiveKit

final class ResourceManagerTests: XCTestCase {
    var requestor = SpyRequestor(temporaryURL: URL(fileURLWithPath: "/tmp/temp"))
    var fileManager = MockFileManager()
    var resourceManager: ResourceManager!
    var containerURL: URL!

    override func setUp() {
        self.containerURL = URL(fileURLWithPath: "/tmp/abc123")

        self.resourceManager = ResourceManager(fileManager: self.fileManager, requestor: self.requestor)
    }

    func testPrefetch() throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        let prefetchURL = URL(string: "https://www.example.com/test")!
        let expectation = self.expectation(description: "Download task complete")

        let obsoleteRemoteURL = URL(string: "https://www.example.com/test2")!
        let obsoleteFileURL = self.containerURL.appendingPathComponent(ResourceManager.filename(for: obsoleteRemoteURL))
        try self.fileManager.writeData(prefetchData, to: obsoleteFileURL)

        XCTAssertTrue(self.fileManager.fileURLs.contains(obsoleteFileURL), "Should be a file named after expected filename")
        self.fileManager.contentsOfDirectory.append(obsoleteFileURL)

        self.resourceManager.prefetchContainerURL = containerURL

        self.requestor.responseData = prefetchData
        self.requestor.extraCompletion = {
            DispatchQueue.main.async {
                let expectedURL = self.containerURL.appendingPathComponent(ResourceManager.filename(for: prefetchURL))

                XCTAssertFalse(self.fileManager.fileURLs.contains(obsoleteFileURL), "Should not be a file named after deleted filename")

                XCTAssertTrue(self.fileManager.fileURLs.contains(expectedURL), "Should be a file named after expected filename")
                XCTAssertEqual(prefetchData, self.fileManager.data[expectedURL], "Prefetched data should match downloaded data")

                expectation.fulfill()
            }
        }

        self.resourceManager.prefetchResources(at: [prefetchURL])

        self.wait(for: [expectation], timeout: 1.0)
    }

    func testGetPrefetchedImage() throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        let prefetchURL = URL(string: "https://www.example.com/test")!
        let expectation = self.expectation(description: "Download task complete")

        self.resourceManager.prefetchContainerURL = containerURL

        self.requestor.responseData = prefetchData
        self.requestor.extraCompletion = {
            DispatchQueue.main.async {
                self.resourceManager.getImage(at: prefetchURL, scale: 3) { result in
                    if case .failure = result {
                        XCTFail("Unable to get prefetched image")
                    }

                    expectation.fulfill()
                }
            }
        }

        self.resourceManager.prefetchResources(at: [prefetchURL])

        self.wait(for: [expectation], timeout: 1.0)
    }

    func testMultipleCompletionHandlers() throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        self.resourceManager.prefetchContainerURL = containerURL

        let prefetchURL = URL(string: "https://www.example.com/test")!
        let expectations = [
            self.expectation(description: "First completion handler called"),
            self.expectation(description: "Second completion handler called"),
        ]

        self.resourceManager.getImage(at: prefetchURL, scale: 3) { result in
            if case .failure(let error) = result {
                XCTFail("Failed to download or decode image: \(error)")
            }

            expectations[0].fulfill()
        }

        self.resourceManager.getImage(at: prefetchURL, scale: 3) { result in
            if case .failure(let error) = result {
                XCTFail("Failed to download or decode image: \(error)")
            }

            expectations[1].fulfill()
        }

        self.wait(for: expectations, timeout: 1.0)
    }

    func testInvalidImage() throws {
        let prefetchData = Data(base64Encoded: "aVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQAB")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        self.resourceManager.prefetchContainerURL = containerURL

        let prefetchURL = URL(string: "https://www.example.com/test")!
        let expectation = self.expectation(description: "Completion handler called")

        self.resourceManager.getImage(at: prefetchURL, scale: 3) { result in
            defer {
                expectation.fulfill()
            }

            guard case .failure(ApptentiveError.resourceNotDecodableAsImage) = result else {
                return XCTFail("Invalid image succeeded or failed with wrong error.")
            }
        }

        self.wait(for: [expectation], timeout: 1.0)
    }

    func testDownloadError() throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        self.resourceManager.prefetchContainerURL = containerURL

        let prefetchURL = URL(string: "https://www.example.com/test")!
        let expectation = self.expectation(description: "Completion handler called")

        self.requestor.error = HTTPClientError.serverError(HTTPURLResponse(url: prefetchURL, mimeType: nil, expectedContentLength: 1, textEncodingName: nil), nil)

        self.resourceManager.getImage(at: prefetchURL, scale: 3) { result in
            defer {
                expectation.fulfill()
            }

            guard case .failure(HTTPClientError.serverError) = result else {
                return XCTFail("Invalid image succeeded or failed with wrong error.")
            }
        }

        self.wait(for: [expectation], timeout: 1.0)
    }

    func testNoTempURL() throws {
        let prefetchData = Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==")!
        try self.fileManager.writeData(prefetchData, to: URL(fileURLWithPath: "/tmp/temp"))

        self.resourceManager.prefetchContainerURL = containerURL

        let prefetchURL = URL(string: "https://www.example.com/test")!
        let expectation = self.expectation(description: "Completion handler called")
        self.requestor.temporaryURL = nil

        self.resourceManager.getImage(at: prefetchURL, scale: 3) { result in
            defer {
                expectation.fulfill()
            }

            guard case .failure(ApptentiveError.internalInconsistency) = result else {
                return XCTFail("Invalid image succeeded or failed with wrong error.")
            }
        }

        self.wait(for: [expectation], timeout: 1.0)
    }
}
