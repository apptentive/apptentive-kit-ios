//
//  MessageManager.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import OSLog
import UIKit

@MainActor protocol MessageManagerDelegate: AnyObject, Sendable {
    // This protocol's methods are called on a background queue.
    func messageManagerMessagesDidChange(_ messageList: [MessageList.Message], context: MessageList.AttachmentContext?)
    func messageManagerDraftMessageDidChange(_ draftMessage: MessageList.Message, context: MessageList.AttachmentContext?)
}

@MainActor protocol MessageManagerApptentiveDelegate: AnyObject, Sendable {
    func setUnreadMessageCount(_ unreadMessageCount: Int)
}

actor MessageManager {
    private(set) var foregroundPollingInterval: TimeInterval
    private(set) var backgroundPollingInterval: TimeInterval
    var customData: CustomData?
    let notificationCenter: NotificationCenter
    var attachmentManager: AttachmentManager?
    let fileManager: FileManager
    var draftAttachmentNumber: Int
    var unreadMessageCount: Int {
        didSet {
            guard let messageManagerApptentiveDelegate = self.messageManagerApptentiveDelegate else {
                return
            }

            let unreadMessageCount = self.unreadMessageCount

            Task {
                await messageManagerApptentiveDelegate.setUnreadMessageCount(unreadMessageCount)
            }
        }
    }

    var automatedMessage: MessageList.Message?

    var messages: [MessageList.Message] {
        var messages = self.messageList.messages

        if let automatedMessage = self.automatedMessage {
            messages.append(automatedMessage)
        }

        return messages
    }

    var messageManagerApptentiveDelegate: MessageManagerApptentiveDelegate?

    weak var delegate: MessageManagerDelegate?

    var lastDownloadedMessageID: String? {
        self.messageList.lastDownloadedMessageID
    }

    var attachmentContext: MessageList.AttachmentContext? {
        guard let attachmentManager = self.attachmentManager else {
            return nil
        }

        return MessageList.AttachmentContext(cacheContainerURL: attachmentManager.cacheContainerURL, savedContainerURL: attachmentManager.savedContainerURL)
    }

    private var messageList: MessageList {
        didSet {
            guard let delegate = self.delegate else {
                return
            }

            let messageList = self.messageList
            let attachmentContext = self.attachmentContext

            if self.messageList != oldValue {
                Task {
                    if self.messageList.messages != oldValue.messages {
                        await delegate.messageManagerMessagesDidChange(messageList.messages, context: attachmentContext)
                    }

                    if self.messageList.draftMessage != oldValue.draftMessage {
                        await delegate.messageManagerDraftMessageDidChange(messageList.draftMessage, context: attachmentContext)
                    }

                    self.messageListNeedsSaving = true
                }
            }
        }
    }

    var messagesNeedDownloading: Bool {
        let timeSinceLastFetch = Date().timeIntervalSince(self.messageList.lastFetchDate ?? .distantPast)

        return timeSinceLastFetch > self.pollingInterval || self.forceMessageDownload
    }

    var forceMessageDownload: Bool = false

    var saver: Saver<MessageList>?

    init(notificationCenter: NotificationCenter) {
        self.messageList = MessageList(messages: [], draftMessage: .init(nonce: "draft", status: .draft))
        self.messageListNeedsSaving = false
        self.foregroundPollingInterval = 30
        self.backgroundPollingInterval = 300
        self.notificationCenter = notificationCenter
        self.draftAttachmentNumber = 1
        self.fileManager = FileManager()

        self.unreadMessageCount = 0
        notificationCenter.addObserver(self, selector: #selector(payloadSending), name: Notification.Name.payloadSending, object: nil)
        notificationCenter.addObserver(self, selector: #selector(payloadSent), name: Notification.Name.payloadSent, object: nil)
        notificationCenter.addObserver(self, selector: #selector(payloadFailed), name: Notification.Name.payloadFailed, object: nil)
    }

    func setPollingIntervals(foreground: TimeInterval, background: TimeInterval) {
        self.foregroundPollingInterval = foreground
        self.backgroundPollingInterval = background
    }

    func setForceMessageDownload() {
        self.forceMessageDownload = true
    }

    func setCustomData(_ customData: CustomData) {
        self.customData = customData
    }

    func setDelegate(_ delegate: MessageManagerDelegate?) {
        self.delegate = delegate

        if let _ = self.delegate {
            // When presenting, trigger a refresh of the message list at the next opportunity.
            self.messageList.lastFetchDate = .distantPast
        } else {
            // When closing, clear out any unsent custom data and/or automated message.
            self.customData = nil
            self.automatedMessage = nil
        }
    }

    func setApptentiveDelegate(_ apptentiveDelegate: MessageManagerApptentiveDelegate?) {
        self.messageManagerApptentiveDelegate = apptentiveDelegate
    }

    func setDraftMessageBody(_ body: String?) {
        self.draftMessage.body = body
    }

    func setAttachmentManager(_ attachmentManager: AttachmentManager?) {
        self.attachmentManager = attachmentManager
    }

    func makeSaver(containerURL: URL, filename: String, encryptionKey: Data?) {
        self.saver = Self.createSaver(containerURL: containerURL, filename: filename, fileManager: FileManager(), encryptionKey: encryptionKey)
    }

    func destroySaver() {
        self.saver = nil
    }

    func load(from loader: Loader, for record: ConversationRoster.Record) throws {
        if let loadedMessageList = try loader.loadMessages(for: record) {
            self.messageList.messages = Self.merge(loadedMessageList.messages, with: self.messageList.messages, attachmentManager: self.attachmentManager, fileManager: self.fileManager)
            self.messageList.draftMessage = loadedMessageList.draftMessage
            self.draftAttachmentNumber = loadedMessageList.draftMessage.attachments.count + 1

            if self.messageList.lastFetchDate ?? .distantPast < loadedMessageList.lastFetchDate ?? .distantPast {
                self.messageList.lastFetchDate = loadedMessageList.lastFetchDate
                self.messageList.lastDownloadedMessageID = loadedMessageList.lastDownloadedMessageID
                self.messageList.additionalDownloadableMessagesExist = loadedMessageList.additionalDownloadableMessagesExist
            }
        }
    }

    func updateReadMessage(with messageNonce: String) throws {
        guard let index = self.messageList.messages.firstIndex(where: { $0.nonce == messageNonce }) else { return }

        if self.messageList.messages[index].status == .unread {
            self.messageList.messages[index].status = .read
            self.setUnreadMessageCount()
            try self.saveMessagesIfNeeded()
        }
    }

    /// Updates the message list with a response from the API.
    /// - Parameter messagesResponse: The API response from the messages endpoint.
    /// - Returns: Whether any new messages were received.
    func update(with messagesResponse: MessagesResponse) -> Bool {
        self.messageList.messages = Self.merge(self.messageList.messages, with: messagesResponse.messages.map { Self.convert(downloadedMessage: $0) }, attachmentManager: self.attachmentManager, fileManager: self.fileManager)
        self.messageList.additionalDownloadableMessagesExist = messagesResponse.hasMore
        self.messageList.lastDownloadedMessageID = messagesResponse.endsWith ?? self.messageList.lastDownloadedMessageID
        self.messageList.lastFetchDate = Date()

        self.forceMessageDownload = self.messageList.additionalDownloadableMessagesExist

        let oldUnreadCount = self.unreadMessageCount
        self.setUnreadMessageCount()

        return self.unreadMessageCount > oldUnreadCount
    }

    func setAutomatedMessageBody(_ body: String?) {
        self.automatedMessage = body.flatMap { MessageList.Message(nonce: "automated", body: $0, isAutomated: true) }
    }

    var draftMessage: MessageList.Message {
        get {
            self.messageList.draftMessage
        }
        set {
            self.messageList.draftMessage = newValue
        }
    }

    func addDraftAttachment(data: Data, name: String?, mediaType: String, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        guard let attachmentManager = self.attachmentManager else {
            throw MessageError.missingAttachmentManager
        }

        let index = self.messageList.draftMessage.attachments.count
        let filename = self.filename(for: name, mediaType: mediaType)

        let url = try await attachmentManager.store(data: data, filename: filename)
        let newAttachment = MessageList.Message.Attachment(contentType: mediaType, filename: filename, storage: .saved(path: url.lastPathComponent), thumbnailData: nil)

        self.messageList.draftMessage.attachments.append(newAttachment)

        AttachmentManager.createThumbnail(of: thumbnailSize, scale: thumbnailScale, for: url) { result in
            if case .success(let image) = result, let thumbnailData = image.pngData() {
                Task {
                    await self.setDraftAttachmentThumbnailData(thumbnailData, forAttachmentAt: index)
                }
            }
        }

        return url
    }

    func addDraftAttachment(url: URL, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        guard let attachmentManager = self.attachmentManager else {
            throw MessageError.missingAttachmentManager
        }

        let filename = url.lastPathComponent
        let url = try await attachmentManager.store(url: url, filename: filename)
        let newAttachment = MessageList.Message.Attachment(contentType: AttachmentManager.mediaType(for: filename), filename: filename, storage: .saved(path: url.lastPathComponent), thumbnailData: nil)

        let index = self.messageList.draftMessage.attachments.count
        self.messageList.draftMessage.attachments.append(newAttachment)

        AttachmentManager.createThumbnail(of: thumbnailSize, scale: thumbnailScale, for: url) { result in
            if case .success(let image) = result, let thumbnailData = image.pngData() {
                Task {
                    await self.setDraftAttachmentThumbnailData(thumbnailData, forAttachmentAt: index)
                }
            }
        }

        return url
    }

    func removeDraftAttachment(at index: Int) async throws {
        guard let attachmentManager = self.attachmentManager else {
            throw MessageError.missingAttachmentManager
        }

        let attachmentToRemove = self.messageList.draftMessage.attachments[index]
        try await attachmentManager.removeStorage(for: attachmentToRemove)
        self.messageList.draftMessage.attachments.remove(at: index)
    }

    func loadAttachment(at index: Int, in message: MessageList.Message, thumbnailSize: CGSize, thumbnailScale: CGFloat) async throws -> URL {
        guard let attachmentManager = self.attachmentManager else {
            throw MessageError.missingAttachmentManager
        }

        guard let messageIndex = self.messageList.messages.firstIndex(of: message) else {
            apptentiveCriticalError("Can't find index of message in message list")
            throw ApptentiveError.internalInconsistency
        }

        let attachment = message.attachments[index]

        let localURL = try await attachmentManager.download(
            attachment,
            progress: { progress in
                Task {
                    await self.setMessageAttachmentDownloadProgress(Float(progress), forAttachmentAt: index, inMessageAt: messageIndex)
                }
            })

        self.messageList.messages[messageIndex].attachments[index].storage = .cached(path: localURL.lastPathComponent)

        if attachment.thumbnailData == nil {
            AttachmentManager.createThumbnail(of: thumbnailSize, scale: thumbnailScale, for: localURL) { result in
                if case .success(let image) = result, let thumbnailData = image.pngData() {
                    Task {
                        await self.setMessageAttachmentThumbnailData(thumbnailData, forAttachmentAt: index, inMessageAt: messageIndex)
                    }
                }
            }
        }

        return localURL
    }

    func prepareDraftMessageForSending() throws -> (MessageList.Message, CustomData?) {
        let customData = self.customData
        let message = self.messageList.draftMessage

        guard message.body?.isEmpty == false || message.attachments.isEmpty == false else {
            throw MessageError.emptyBodyAndAttachments
        }

        self.customData = nil
        self.messageList.draftMessage = Self.newDraftMessage()
        self.draftAttachmentNumber = 1

        return (message, customData)
    }

    func prepareAutomatedMessageForSending() throws -> MessageList.Message? {
        let message = self.automatedMessage
        self.automatedMessage = nil

        return message
    }

    /// Called when a message is added to the payload queue so that it can be tracked in the message list.
    /// - Parameters:
    ///   - message: The message that was enqueued.
    ///   - nonce: The `nonce` (SDK-assigned unique ID) of the message.
    func addQueuedMessage(_ message: MessageList.Message, with nonce: String) {
        var newMessage = message

        newMessage.nonce = nonce
        newMessage.sentDate = Date()
        newMessage.status = .queued

        self.messageList.messages.append(newMessage)
    }

    func saveMessagesIfNeeded() throws {
        if self.messageListNeedsSaving {
            try self.saveMessages()
        }
    }

    func saveMessages() throws {
        try self.saver?.save(self.messageList)
        self.messageListNeedsSaving = false
    }

    func deleteCachedMessages() async throws {
        self.messageList = MessageList(messages: [], draftMessage: Self.newDraftMessage())
        try await self.attachmentManager?.deleteCachedAttachments()
    }

    @objc nonisolated func payloadSending(_ notification: Notification) {
        guard let payload = notification.userInfo?[PayloadSender.payloadKey] as? Payload else {
            return apptentiveCriticalError("Should be able to find payload in payload sender notification's userInfo.")
        }

        Task {
            await self.updateStatus(to: .sending, for: payload.identifier)
        }
    }

    @objc nonisolated func payloadSent(_ notification: Notification) {
        guard let payload = notification.userInfo?[PayloadSender.payloadKey] as? Payload else {
            return apptentiveCriticalError("Should be able to find payload in payload sender notification's userInfo.")
        }

        Task {
            await self.updateStatus(to: .sent, for: payload.identifier)
        }
    }

    @objc nonisolated func payloadFailed(_ notification: Notification) {
        guard let payload = notification.userInfo?[PayloadSender.payloadKey] as? Payload else {
            return apptentiveCriticalError("Should be able to find payload in payload sender notification's userInfo.")
        }

        Task {
            await self.updateStatus(to: .failed, for: payload.identifier)
        }
    }

    static func createSaver(containerURL: URL, filename: String, fileManager: FileManager, encryptionKey: Data?) -> EncryptedPropertyListSaver<MessageList> {
        return EncryptedPropertyListSaver<MessageList>(containerURL: containerURL, filename: filename, fileManager: fileManager, encryptionKey: encryptionKey)
    }

    static func merge(_ existing: [MessageList.Message], with newer: [MessageList.Message], attachmentManager: AttachmentManager?, fileManager: FileManager) -> [MessageList.Message] {
        var messagesByNonce = Dictionary(grouping: existing, by: { $0.nonce }).compactMapValues { $0.first }

        for message in newer {
            if let older = messagesByNonce[message.nonce] {
                messagesByNonce[message.nonce] = self.merge(older, with: message, attachmentManager: attachmentManager, fileManager: fileManager)
            } else {
                messagesByNonce[message.nonce] = message
            }
        }

        return Array(messagesByNonce.values).sorted(by: { $0.sentDate < $1.sentDate })
    }

    static func merge(_ existing: MessageList.Message, with newer: MessageList.Message, attachmentManager: AttachmentManager?, fileManager: FileManager) -> MessageList.Message {
        var result = newer

        if existing.status == .read {
            result.status = .read
        }

        for (index, existingAttachment) in existing.attachments.enumerated() {
            guard result.attachments.count > index else {
                Logger.messages.error("Mismatch of server-side and client-side attachment counts.")
                continue
            }

            if attachmentManager?.cacheFileExists(for: existingAttachment, using: fileManager) == true {
                result.attachments[index].storage = existingAttachment.storage
            }
            result.attachments[index].thumbnailData = existingAttachment.thumbnailData
        }

        return result
    }

    static func convert(downloadedMessage: MessagesResponse.Message) -> MessageList.Message {
        let attachments = downloadedMessage.attachments.map { (attachment) -> MessageList.Message.Attachment in
            var filename = attachment.filename

            // Append an extension to filename if we can figure it out from the content type and there isn't one already.
            if let pathExtension = AttachmentManager.pathExtension(for: attachment.contentType), filename.components(separatedBy: ".").count < 2 {
                filename += ".\(pathExtension)"
            }

            return MessageList.Message.Attachment(contentType: attachment.contentType, filename: filename, storage: .remote(attachment.url, size: attachment.size))
        }

        let sender = downloadedMessage.sender.flatMap { sender in
            MessageList.Message.Sender(name: sender.name, profilePhoto: sender.profilePhoto)
        }

        return MessageList.Message(
            id: downloadedMessage.id, nonce: downloadedMessage.nonce, body: downloadedMessage.body, attachments: attachments, sender: sender, sentDate: downloadedMessage.sentDate, isAutomated: downloadedMessage.isAutomated ?? false,
            isHidden: downloadedMessage.isHidden ?? false, status: Self.status(of: downloadedMessage))
    }

    static func status(of downloadedMessage: MessagesResponse.Message) -> MessageList.Message.Status {
        return downloadedMessage.sentFromDevice || downloadedMessage.isAutomated == true ? .sent : .unread
    }

    static func newDraftMessage() -> MessageList.Message {
        return .init(nonce: "draft", status: .draft)
    }

    private func filename(for name: String?, mediaType: String) -> String {
        var result =
            name
            ?? {
                let name = "Attachment \(self.draftAttachmentNumber)"  // This is only visible in the (non-localized) dashboard.
                self.draftAttachmentNumber += 1
                return name
            }()

        if let pathExtension = AttachmentManager.pathExtension(for: mediaType) {
            result += ".\(pathExtension)"
        }

        return result
    }

    private func setUnreadMessageCount() {
        self.unreadMessageCount = self.messageList.messages.filter { $0.status == .unread }.count
    }

    private var messageListNeedsSaving: Bool

    private var pollingInterval: TimeInterval {
        self.delegate != nil ? self.foregroundPollingInterval : self.backgroundPollingInterval
    }

    private func setDraftAttachmentThumbnailData(_ thumbnailData: Data, forAttachmentAt attachmentIndex: Int) {
        self.messageList.draftMessage.attachments[attachmentIndex].thumbnailData = thumbnailData
    }

    private func setMessageAttachmentThumbnailData(_ thumbnailData: Data, forAttachmentAt attachmentIndex: Int, inMessageAt messageIndex: Int) {
        self.messageList.messages[messageIndex].attachments[attachmentIndex].thumbnailData = thumbnailData
    }

    private func setMessageAttachmentDownloadProgress(_ progress: Float, forAttachmentAt attachmentIndex: Int, inMessageAt messageIndex: Int) {
        self.messageList.messages[messageIndex].attachments[attachmentIndex].downloadProgress = progress
    }

    private func updateStatus(to status: MessageList.Message.Status, for identifier: String) async {
        if let index = self.messageList.messages.firstIndex(where: { $0.nonce == identifier }) {
            self.messageList.messages[index].status = status

            if status == .queued {
                // Move the attachments from "saved" to "cached" so that the system can jettison them if needed.
                let sentMessage = self.messageList.messages[index]
                do {
                    guard let attachmentManager = self.attachmentManager else {
                        throw MessageError.missingAttachmentManager
                    }

                    for (attachmentIndex, attachment) in sentMessage.attachments.enumerated() {
                        self.messageList.messages[index].attachments[attachmentIndex].storage = try await attachmentManager.cacheQueuedAttachment(attachment)
                    }

                } catch let error {
                    Logger.attachments.error("Unable to move queued attachments for payload \(identifier): \(error).")
                }
            }
        }  // else this wasn't a message payload.
    }
}

enum MessageError: Error {
    case missingAttachmentManager
    case emptyBodyAndAttachments
}
