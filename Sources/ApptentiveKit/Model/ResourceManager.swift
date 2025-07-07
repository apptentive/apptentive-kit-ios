//
//  ResourceManager.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/11/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import OSLog
import UIKit

actor ResourceManager {
    /// An object conforming to `FileManaging` used to manage persistent storage.
    let fileManager: FileManaging

    /// An object conforming to `HTTPRequesting` used to request data from URLs.
    let requestor: HTTPRequesting

    /// Initializes the ResourceManager with the specified file managing and HTTP requesting objects.
    /// - Parameter requestor: An object conforming to `HTTPRequesting` that is used to download resources.
    init(requestor: HTTPRequesting) {
        self.init(fileManager: FileManager(), requestor: requestor)
    }

    init(fileManager: FileManaging, requestor: HTTPRequesting) {
        self.fileManager = fileManager
        self.requestor = requestor
    }

    /// The names of files that are present in the prefetch storage.
    var prefetchedFilenames = Set<String>()

    /// The URL for the directory to use for prefetch storage.
    private(set) var prefetchContainerURL: URL?

    func setPrefetchContainerURL(_ prefetchContainerURL: URL?) {
        self.prefetchContainerURL = prefetchContainerURL
        self.createContainerDirectoryIfNeeded()
        self.resetPrefetchedFiles()
    }

    /// Retrieves an image from the specified URL.
    /// - Parameters:
    ///   - url: A URL pointing to image data.
    ///   - scale: The number of pixels per point defined by the image.
    /// - Returns: The image at the specified URL.
    /// - Throws: An error if retrieving the image fails.
    func getImage(at url: URL, scale: CGFloat) async throws -> UIImage {
        let data = try await self.getResource(with: url)
        guard let image = UIImage(data: data, scale: scale) else {
            throw ApptentiveError.resourceNotDecodableAsImage
        }

        return image
    }

    /// Retrieves data from the specified URL.
    /// - Parameters:
    ///   - url: The URL pointing to the data.
    ///   - isPrefetch: Whether the data should be saved in the prefetch storage.
    /// - Returns: The data retrieved from the specified URL.
    /// - Throws: An error if retrieving the dtat fails.
    func getResource(with url: URL, isPrefetch: Bool = false) async throws -> Data {
        let filename = Self.filename(for: url)

        if self.prefetchedFilenames.contains(filename) {
            return try self.loadFromPrefetchStorage(with: filename)
        } else {
            return try await self.download(at: url, isPrefetch: isPrefetch)
        }
    }

    /// Prefetches resources with the given URLs.
    ///
    /// Previously-fetched files whose names do not correspond to the list of URLs will be deleted from the prefetch storage.
    /// - Parameter urls: The URLs corresponding to the resources to prefetch.
    func prefetchResources(at urls: [URL]) async {
        guard let prefetchContainerURL = self.prefetchContainerURL else {
            return
        }

        let updatedFilenames = Set(urls.map { Self.filename(for: $0) })
        let evictedFilenames = self.prefetchedFilenames.subtracting(updatedFilenames)

        for evictedFilename in evictedFilenames {
            let evictedURL = prefetchContainerURL.appendingPathComponent(evictedFilename)

            do {
                try self.fileManager.removeItem(at: evictedURL)
                self.prefetchedFilenames.remove(evictedFilename)
            } catch let error {
                Logger.resources.error("Unable to delete obsolete file at \(evictedURL): \(error)")
            }
        }

        for url in urls {
            if self.prefetchedFilenames.contains(Self.filename(for: url)) {
                continue
            }

            do {
                let _ = try await self.download(at: url, isPrefetch: true)
                self.prefetchedFilenames.insert(Self.filename(for: url))
                Logger.resources.debug("Successfully prefetched \(url)")
            } catch let error {
                Logger.resources.error("Unable to download resource at \(url): \(error)")
            }
        }
    }

    private func loadFromPrefetchStorage(with filename: String) throws -> Data {
        guard let url = self.prefetchContainerURL?.appendingPathComponent(filename) else {
            throw ApptentiveError.internalInconsistency
        }

        return try self.fileManager.readData(from: url)
    }

    private var downloadTasks = [URL: Task<Data, Error>]()

    /// Downloads data from the specified URL.
    /// - Parameters:
    ///   - url: The URL from which to download the data.
    ///   - isPrefetch: Whether to save a valid response in the prefetch storage.
    /// - Returns: The data downloaded from the specified URL.
    /// - Throws: An error if retrieving the data fails.
    private func download(at url: URL, isPrefetch: Bool) async throws -> Data {
        if self.downloadTasks[url] == nil {
            self.downloadTasks[url] = Task {
                let (tempURL, _) = try await self.requestor.download(from: url, delegate: nil)
                let data = try self.fileManager.readData(from: tempURL)
                if let prefetchContainerURL = self.prefetchContainerURL, isPrefetch {
                    try self.fileManager.moveItem(at: tempURL, to: prefetchContainerURL.appendingPathComponent(Self.filename(for: url)))
                }
                return data
            }
        }

        defer {
            self.downloadTasks[url] = nil
        }

        guard let task = self.downloadTasks[url] else {
            throw ApptentiveError.internalInconsistency
        }

        return try await task.value
    }

    private func createContainerDirectoryIfNeeded() {
        guard let prefetchContainerURL = self.prefetchContainerURL else {
            Logger.resources.warning("Resource prefetching is disabled due to missing container URL")
            return
        }

        var isDirectory: Bool = false

        do {
            if !fileManager.fileExists(at: prefetchContainerURL, isDirectory: &isDirectory) {
                try fileManager.createDirectory(at: prefetchContainerURL)
            } else if !isDirectory {
                Logger.resources.error("File exists at container directory path.")
                throw ApptentiveError.internalInconsistency
            }
        } catch let error {
            Logger.resources.error("Unable to enumerate files in prefetch cache: \(error)")
        }
    }

    private func resetPrefetchedFiles() {
        self.prefetchedFilenames.removeAll()
        for key in self.downloadTasks.keys {
            self.downloadTasks[key]?.cancel()
        }

        guard let prefetchContainerURL = self.prefetchContainerURL else {
            Logger.resources.warning("Resource prefetching is disabled due to missing container URL")
            return
        }

        do {
            self.prefetchedFilenames = Set(try self.fileManager.contentsOfDirectory(at: prefetchContainerURL).map { $0.lastPathComponent })

        } catch let error {
            Logger.resources.error("Unable to enumerate files in prefetch cache: \(error)")
        }
    }

    static func filename(for url: URL) -> String {
        let escapedHost = url.host ?? "prefetch_host"
        let escapedPath = url.path.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "/", with: "_")
        return "\(escapedHost)_\(escapedPath)"
    }
}
