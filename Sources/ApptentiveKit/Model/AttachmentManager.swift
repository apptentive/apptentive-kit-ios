//
//  AttachmentManager.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 1/28/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import QuickLookThumbnailing
import UIKit

protocol AttachmentURLProviding {
    func url(for attachment: MessageList.Message.Attachment) -> URL?
}

class AttachmentManager: AttachmentURLProviding {
    let fileManager: FileManager
    let requestor: HTTPRequesting
    let cacheContainerURL: URL
    let savedContainerURL: URL

    static let attachmentFilenameSeparator = "#"

    init(fileManager: FileManager, requestor: HTTPRequesting, cacheContainerURL: URL, savedContainerURL: URL) {
        self.fileManager = fileManager
        self.requestor = requestor
        self.cacheContainerURL = cacheContainerURL
        self.savedContainerURL = savedContainerURL
    }

    deinit {
        for observation in self.progressObservations.values {
            observation.invalidate()
        }
    }

    func store(data: Data, filename: String) throws -> URL {
        let path = Self.newAttachmentPath(filename: filename)
        let attachmentURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)

        ApptentiveLogger.messageCenterAttachment.debug("Trying to write attachment data to \(attachmentURL.path).")
        try data.write(to: attachmentURL)
        ApptentiveLogger.messageCenterAttachment.debug("Successfully wrote attachment data to \(attachmentURL.path).")

        return attachmentURL
    }

    func store(url: URL, filename: String) throws -> URL {
        let path = Self.newAttachmentPath(filename: filename)
        let attachmentURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)

        if url.startAccessingSecurityScopedResource() {
            ApptentiveLogger.messageCenterAttachment.debug("Trying to write attachment data to \(attachmentURL.path).")
            try self.fileManager.copyItem(at: url, to: attachmentURL)
            ApptentiveLogger.messageCenterAttachment.debug("Successfully wrote attachment data to \(attachmentURL.path).")
        }
        url.stopAccessingSecurityScopedResource()
        return attachmentURL
    }

    func removeStorage(for attachment: MessageList.Message.Attachment) throws {
        if let attachmentURL = self.url(for: attachment) {
            try self.fileManager.removeItem(at: attachmentURL)
        }  // else it likely doesn't have a sidecar file.
    }

    func url(for attachment: MessageList.Message.Attachment) -> URL? {
        switch attachment.storage {
        case .cached(let path):
            return URL(fileURLWithPath: path, relativeTo: self.cacheContainerURL)

        case .saved(let path):
            return URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)

        default:
            return nil
        }
    }

    func cacheFileExists(for attachment: MessageList.Message.Attachment) -> Bool {
        if let url = self.url(for: attachment) {
            return self.fileManager.fileExists(atPath: url.path)
        } else {
            return false
        }
    }

    func cacheQueuedAttachment(_ attachment: MessageList.Message.Attachment) throws -> MessageList.Message.Attachment.Storage {
        if case .saved(let path) = attachment.storage {
            let savedURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)
            let cacheURL = URL(fileURLWithPath: path, relativeTo: self.cacheContainerURL)
            ApptentiveLogger.messageCenterAttachment.debug("Trying to write attachment data from \(savedURL.path) to \(cacheURL.path).")
            try self.fileManager.moveItem(at: savedURL, to: cacheURL)
            ApptentiveLogger.messageCenterAttachment.debug("Successfully wrote attachment data to \(cacheURL.path).")
            return .cached(path: path)
        } else {
            return attachment.storage
        }
    }

    func download(_ attachment: MessageList.Message.Attachment, completion: @escaping (Result<URL, Error>) -> Void, progress: ((Double) -> Void)? = nil) {
        switch attachment.storage {
        case .remote(let remoteURL, size: _):
            let localURL = URL(fileURLWithPath: Self.newAttachmentPath(filename: attachment.filename), relativeTo: self.cacheContainerURL)
            self.downloadData(from: remoteURL, to: localURL, completion: completion, progress: progress)

        case .cached(let path):
            completion(
                Result(catching: {
                    let localURL = URL(fileURLWithPath: path, relativeTo: self.cacheContainerURL)
                    guard self.fileManager.fileExists(atPath: localURL.path) else {
                        throw ApptentiveError.internalInconsistency
                    }
                    return localURL
                }))

        case .saved(let path):
            completion(
                Result(catching: {
                    let localURL = URL(fileURLWithPath: path, relativeTo: self.savedContainerURL)
                    guard self.fileManager.fileExists(atPath: localURL.path) else {
                        throw ApptentiveError.internalInconsistency
                    }
                    return localURL
                }))

        case .inMemory(let data):
            completion(
                Result(catching: {
                    let localURL = URL(fileURLWithPath: Self.newAttachmentPath(filename: attachment.filename), relativeTo: self.cacheContainerURL)
                    try data.write(to: localURL)
                    return localURL
                }))
        }

        progress?(1)
    }

    static func friendlyFilename(for url: URL) -> String {
        return url.lastPathComponent.split(separator: Character(self.attachmentFilenameSeparator)).suffix(from: 1).joined(separator: self.attachmentFilenameSeparator)
    }

    static func mediaType(for filename: String) -> String {
        if let pathExtension = filename.components(separatedBy: ".").last {
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    return mimetype as String
                }
            }
        }

        return "application/octet-stream"
    }

    static func pathExtension(for mediaType: String) -> String? {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, mediaType as NSString, nil)?.takeRetainedValue() {
            if let pathExtension = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassFilenameExtension)?.takeRetainedValue() {
                return pathExtension as String
            }
        }
        return nil
    }

    // Note: completion may be called multiple times.
    static func createThumbnail(of size: CGSize, for url: URL, completion: @escaping (Result<UIImage, Error>) -> Void) {
        if #available(iOS 13.0, *) {
            let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: UIScreen.main.scale, representationTypes: .all)

            QLThumbnailGenerator.shared.generateRepresentations(for: request) { (thumbnail, type, error) in
                DispatchQueue.main.async {
                    guard let thumbnail = thumbnail else {
                        return completion(.failure(error ?? AttachmentError.unableToCreateThumbnail))
                    }

                    return completion(.success(thumbnail.uiImage))
                }
            }
        } else {
            completion(.failure(AttachmentError.unableToCreateThumbnail))
        }
    }

    // MARK: - Private

    private var progressObservations = [URL: NSKeyValueObservation]()

    private func downloadData(from remoteURL: URL, to localURL: URL, completion: @escaping (Result<URL, Error>) -> Void, progress: ((Double) -> Void)? = nil) {
        let cancellable = self.requestor.download(remoteURL) { tempURL, response, error in
            completion(
                Result(catching: {
                    if let error = error {
                        throw error
                    }

                    guard let tempURL = tempURL else {
                        throw AttachmentError.missingDownloadedURL(response)
                    }
                    ApptentiveLogger.messageCenterAttachment.debug("Trying to write attachment data from \(remoteURL.path) to \(localURL.path).")
                    try self.fileManager.moveItem(at: tempURL, to: localURL)
                    ApptentiveLogger.messageCenterAttachment.debug("Successfully wrote attachment data to \(localURL.path).")
                    self.progressObservations.removeValue(forKey: remoteURL)?.invalidate()

                    return localURL
                })
            )
        }

        if let cancellable = cancellable as? URLSessionTaskCancellable {
            self.progressObservations[remoteURL] = cancellable.task.progress.observe(\.fractionCompleted) { taskProgress, _ in
                progress?(taskProgress.fractionCompleted)
            }
        }
    }

    private static func newAttachmentPath(filename: String) -> String {
        return "\(UUID().uuidString)\(self.attachmentFilenameSeparator)\(filename)"
    }

    enum AttachmentError: Error {
        case missingDownloadedURL(URLResponse?)
        case unableToCreateThumbnail
    }
}
