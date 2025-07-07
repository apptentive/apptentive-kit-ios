//
//  AttachmentManager.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/28/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import OSLog
import QuickLookThumbnailing
import UIKit

protocol AttachmentURLProviding {
    func url(for attachment: MessageList.Message.Attachment) -> URL?
}

actor AttachmentManager: NSObject, AttachmentURLProviding, URLSessionDownloadDelegate {
    let fileManager: FileManager
    let requestor: HTTPRequesting
    let cacheContainerURL: URL
    let savedContainerURL: URL

    static let attachmentFilenameSeparator = "#"

    init(requestor: HTTPRequesting, cacheContainerURL: URL, savedContainerURL: URL) {
        self.fileManager = FileManager()
        self.requestor = requestor
        self.cacheContainerURL = cacheContainerURL
        self.savedContainerURL = savedContainerURL
    }

    func store(data: Data, filename: String) throws -> URL {
        let path = Self.newAttachmentPath(filename: filename)
        let attachmentURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)

        Logger.attachments.debug("Trying to write attachment data to \(attachmentURL.path).")
        try data.write(to: attachmentURL)
        Logger.attachments.debug("Successfully wrote attachment data to \(attachmentURL.path).")

        return attachmentURL
    }

    func store(url: URL, filename: String) throws -> URL {
        let path = Self.newAttachmentPath(filename: filename)
        let attachmentURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)

        if url.startAccessingSecurityScopedResource() {
            Logger.attachments.debug("Trying to write attachment data to \(attachmentURL.path).")
            try self.fileManager.copyItem(at: url, to: attachmentURL)
            Logger.attachments.debug("Successfully wrote attachment data to \(attachmentURL.path).")
        }
        url.stopAccessingSecurityScopedResource()
        return attachmentURL
    }

    func removeStorage(for attachment: MessageList.Message.Attachment) throws {
        if let attachmentURL = self.url(for: attachment) {
            if self.fileManager.fileExists(atPath: attachmentURL.path) {
                try self.fileManager.removeItem(at: attachmentURL)
            } else {
                Logger.default.error("File does not exist at attachment URL path when attempting to remove from storage.")
            }
        }  // else it likely doesn't have a sidecar file.
    }

    nonisolated func url(for attachment: MessageList.Message.Attachment) -> URL? {
        switch attachment.storage {
        case .cached(let path):
            return URL(fileURLWithPath: path, relativeTo: self.cacheContainerURL)

        case .saved(let path):
            return URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)

        default:
            return nil
        }
    }

    nonisolated func cacheFileExists(for attachment: MessageList.Message.Attachment, using fileManager: FileManager) -> Bool {
        if let url = self.url(for: attachment) {
            return fileManager.fileExists(atPath: url.path)
        } else {
            return false
        }
    }

    func cacheQueuedAttachment(_ attachment: MessageList.Message.Attachment) throws -> MessageList.Message.Attachment.Storage {
        if case .saved(let path) = attachment.storage {
            let savedURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)
            let cacheURL = URL(fileURLWithPath: path, relativeTo: self.cacheContainerURL)
            Logger.attachments.debug("Trying to write attachment data from \(savedURL.path) to \(cacheURL.path).")
            try self.fileManager.moveItem(at: savedURL, to: cacheURL)
            Logger.attachments.debug("Successfully wrote attachment data to \(cacheURL.path).")
            return .cached(path: path)
        } else {
            return attachment.storage
        }
    }

    func deleteCachedAttachments() throws {
        let cachedFileURLs = try self.fileManager.contentsOfDirectory(at: self.cacheContainerURL, includingPropertiesForKeys: nil)

        for cachedFileURL in cachedFileURLs {
            try self.fileManager.removeItem(at: cachedFileURL)
        }
    }

    func download(_ attachment: MessageList.Message.Attachment, progress: (@Sendable (Double) -> Void)? = nil) async throws -> URL {
        defer {
            progress?(1)
        }

        switch attachment.storage {
        case .remote(let remoteURL, size: _):
            let localURL = URL(fileURLWithPath: Self.newAttachmentPath(filename: attachment.filename), relativeTo: self.cacheContainerURL)
            return try await self.downloadData(from: remoteURL, to: localURL, progress: progress)

        case .cached(let path):
            let localURL = URL(fileURLWithPath: path, relativeTo: self.cacheContainerURL)
            guard self.fileManager.fileExists(atPath: localURL.path) else {
                throw ApptentiveError.internalInconsistency
            }
            return localURL

        case .saved(let path):
            let localURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)
            guard self.fileManager.fileExists(atPath: localURL.path) else {
                throw ApptentiveError.internalInconsistency
            }
            return localURL

        case .inMemory(let data):
            let localURL = URL(fileURLWithPath: Self.newAttachmentPath(filename: attachment.filename), relativeTo: self.cacheContainerURL)
            try data.write(to: localURL)
            return localURL
        }
    }

    static func friendlyFilename(for url: URL) -> String {
        return url.lastPathComponent.split(separator: Character(self.attachmentFilenameSeparator)).suffix(from: 1).joined(separator: self.attachmentFilenameSeparator)
    }

    static func mediaType(for filename: String) -> String {
        return filename.components(separatedBy: ".").last.flatMap { UTType(filenameExtension: $0)?.preferredMIMEType } ?? "application/octet-stream"
    }

    static func pathExtension(for mediaType: String) -> String? {
        return UTType(mimeType: mediaType)?.preferredFilenameExtension
    }

    // Note: completion may be called multiple times.
    static func createThumbnail(of size: CGSize, scale: CGFloat, for url: URL, completion: @Sendable @escaping (Result<UIImage, Error>) -> Void) {
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .all)

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { (thumbnail, type, error) in
            guard let thumbnail = thumbnail else {
                Task {
                    completion(.failure(error ?? AttachmentError.unableToCreateThumbnail))
                }
                return
            }

            let image = thumbnail.uiImage

            Task {
                completion(.success(image))
            }
        }

    }

    // MARK: - Private

    private var progressBlocks = [URL: @Sendable (Double) -> Void]()

    private func downloadData(from remoteURL: URL, to localURL: URL, progress: (@Sendable (Double) -> Void)? = nil) async throws -> URL {
        defer {
            self.progressBlocks.removeValue(forKey: remoteURL)
        }

        self.progressBlocks[remoteURL] = progress

        progress?(0)

        let (tempURL, _) = try await self.requestor.download(from: remoteURL, delegate: self)

        progress?(1)

        Logger.attachments.debug("Trying to write attachment data from \(remoteURL.path) to \(localURL.path).")
        try self.fileManager.moveItem(at: tempURL, to: localURL)
        Logger.attachments.debug("Successfully wrote attachment data to \(localURL.path).")

        return localURL
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        Task {
            guard let remoteURL = downloadTask.originalRequest?.url, let progressBlock = await self.progressBlocks[remoteURL] else {
                return
            }

            progressBlock(Double(totalBytesWritten / totalBytesExpectedToWrite))
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}

    private static func newAttachmentPath(filename: String) -> String {
        return "\(UUID().uuidString)\(self.attachmentFilenameSeparator)\(filename)"
    }

    enum AttachmentError: Error {
        case missingDownloadedURL(URLResponse?)
        case unableToCreateThumbnail
    }
}
