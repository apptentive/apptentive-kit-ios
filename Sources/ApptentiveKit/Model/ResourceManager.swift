//
//  ResourceManager.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/11/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import UIKit

class ResourceManager {
    /// An object conforming to `FileManaging` used to manage persistent storage.
    let fileManager: FileManaging

    /// An object conforming to `HTTPRequesting` used to request data from URLs.
    let requestor: HTTPRequesting

    /// Initializes the ResourceManager with the specified file managing and HTTP requesting objects.
    /// - Parameters:
    ///   - fileManager: The file managing object to use.
    ///   - requestor: The HTTP requesting object to use.
    init(fileManager: FileManaging, requestor: HTTPRequesting) {
        self.fileManager = fileManager
        self.requestor = requestor
    }

    typealias CompletionHandler = (Result<Data, Error>) -> Void

    /// The in-process download tasks.
    var downloads = [URL: HTTPCancellable]()

    /// The completion handlers for in-progress download tasks.
    var completionHandlers = [URL: [CompletionHandler]]()

    /// The names of files that are present in the prefetch storage.
    var prefetchedFilenames = Set<String>()

    /// The URL for the directory to use for prefetch storage.
    var prefetchContainerURL: URL? {
        didSet {
            self.createContainerDirectoryIfNeeded()
            self.resetPrefetchedFiles()
        }
    }

    /// Retrieves an image from the specified URL.
    /// - Parameters:
    ///   - url: A URL pointing to image data.
    ///   - scale: The number of pixels per point defined by the image.
    ///   - completion: A completion handler to be called with the result of the request.
    func getImage(at url: URL, scale: CGFloat, completion: @escaping (Result<UIImage, Error>) -> Void) {
        self.getResource(with: url) { result in
            switch result {
            case .success(let data):
                if let image = UIImage(data: data, scale: scale) {
                    completion(.success(image))
                } else {
                    completion(.failure(ApptentiveError.resourceNotDecodableAsImage))
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Retrieves data from the specified URL.
    /// - Parameters:
    ///   - url: The URL pointing to the data.
    ///   - isPrefetch: Whether the data should be saved in the prefetch storage.
    ///   - completion: A completion handler to be called with the result of the request.
    func getResource(with url: URL, isPrefetch: Bool = false, completion: @escaping (Result<Data, Error>) -> Void) {
        let filename = Self.filename(for: url)

        if self.prefetchedFilenames.contains(filename) {
            self.loadFromPrefetchStorage(with: filename, completion: completion)
        } else {
            self.download(at: url, isPrefetch: isPrefetch, completion: completion)
        }
    }

    /// Prefetches resources with the given URLs.
    ///
    /// Previously-fetched files whose names do not correspond to the list of URLs will be deleted from the prefetch storage.
    /// - Parameter urls: The URLs corresponding to the resources to prefetch.
    func prefetchResources(at urls: [URL]) {
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
                ApptentiveLogger.resources.error("Unable to delete obsolete file at \(evictedURL): \(error)")
            }
        }

        for url in urls {
            if self.prefetchedFilenames.contains(Self.filename(for: url)) {
                continue
            }

            self.download(at: url, isPrefetch: true) { result in
                switch result {
                case .success:
                    self.prefetchedFilenames.insert(Self.filename(for: url))
                    ApptentiveLogger.resources.debug("Successfully prefetched \(url)")

                case .failure(let error):
                    ApptentiveLogger.resources.error("Unable to download resource at \(url): \(error)")
                }
            }
        }
    }

    private func loadFromPrefetchStorage(with filename: String, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(
            Result(catching: {
                guard let url = self.prefetchContainerURL?.appendingPathComponent(filename) else {
                    throw ApptentiveError.internalInconsistency
                }

                return try self.fileManager.readData(from: url)
            }))
    }

    /// Downloads data from the specified URL.
    /// - Parameters:
    ///   - url: The URL from which to download the data.
    ///   - isPrefetch: Whether to save a valid response in the prefetch storage.
    ///   - completion: A completion handler that is called with the result of the download operation.
    private func download(at url: URL, isPrefetch: Bool, completion: @escaping CompletionHandler) {
        self.addCompletionHandler(completion, for: url)

        guard downloads[url] == nil else {
            ApptentiveLogger.resources.info("Already downloading from \(url). Skipping.")
            return
        }

        self.downloads[url] = self.requestor.download(url) { (tempURL, urlRequest, error) in
            defer {
                DispatchQueue.main.async {
                    self.downloads[url] = nil
                    self.completionHandlers[url] = nil
                }
            }

            if let error = error {
                ApptentiveLogger.resources.error("Error with url for ApptentiveImage: \(error)")
                for completionHandler in self.completionHandlers[url] ?? [] {
                    completionHandler(.failure(error))
                }
                return
            }

            guard let tempURL = tempURL else {
                ApptentiveLogger.resources.error("Error with data for ApptentiveImage: \(error)")
                for completionHandler in self.completionHandlers[url] ?? [] {
                    completionHandler(.failure(ApptentiveError.internalInconsistency))
                }
                return
            }

            do {
                let data = try self.fileManager.readData(from: tempURL)

                if let prefetchContainerURL = self.prefetchContainerURL, isPrefetch {
                    try self.fileManager.moveItem(at: tempURL, to: prefetchContainerURL.appendingPathComponent(Self.filename(for: url)))
                }

                for completionHandler in self.completionHandlers[url] ?? [] {
                    completionHandler(.success(data))
                }
            } catch let error {
                for completionHandler in self.completionHandlers[url] ?? [] {
                    completionHandler(.failure(error))
                }
            }
        }
    }

    private func addCompletionHandler(_ completion: @escaping CompletionHandler, for url: URL) {
        if let handlers = self.completionHandlers[url] {
            self.completionHandlers[url] = [completion] + handlers
        } else {
            self.completionHandlers[url] = [completion]
        }
    }

    private func createContainerDirectoryIfNeeded() {
        guard let prefetchContainerURL = self.prefetchContainerURL else {
            ApptentiveLogger.resources.warning("Resource prefetching is disabled due to missing container URL")
            return
        }

        var isDirectory: Bool = false

        do {
            if !fileManager.fileExists(at: prefetchContainerURL, isDirectory: &isDirectory) {
                try fileManager.createDirectory(at: prefetchContainerURL)
            } else if !isDirectory {
                ApptentiveLogger.resources.error("File exists at container directory path.")
                throw ApptentiveError.internalInconsistency
            }
        } catch let error {
            ApptentiveLogger.resources.error("Unable to enumerate files in prefetch cache: \(error)")
        }
    }

    private func resetPrefetchedFiles() {
        self.prefetchedFilenames.removeAll()
        for key in self.downloads.keys {
            self.downloads[key]?.cancel()
        }

        guard let prefetchContainerURL = self.prefetchContainerURL else {
            ApptentiveLogger.resources.warning("Resource prefetching is disabled due to missing container URL")
            return
        }

        do {
            self.prefetchedFilenames = Set(try self.fileManager.contentsOfDirectory(at: prefetchContainerURL).map { $0.lastPathComponent })

        } catch let error {
            ApptentiveLogger.resources.error("Unable to enumerate files in prefetch cache: \(error)")
        }
    }

    static func filename(for url: URL) -> String {
        return String(url.absoluteString.hashValue)
    }
}
