//
//  MessageManager.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

protocol MessageManagerDelegate: AnyObject {
    // This protocol's methods are called on a background queue.
    func messageManagerMessagesDidChange(_ messageList: [MessageList.Message])
    func messageManagerDraftMessageDidChange(_ draftMessage: MessageList.Message)
}

protocol MessageManagerApptentiveDelegate: AnyObject {
    var unreadMessageCount: Int { get set }
}

class MessageManager {
    var foregroundPollingInterval: TimeInterval
    var backgroundPollingInterval: TimeInterval
    var customData: CustomData?
    let notificationCenter: NotificationCenter
    var attachmentManager: AttachmentManager?
    var draftAttachmentNumber: Int
    var unreadMessageCount: Int {
        didSet {
            DispatchQueue.main.async {
                self.messageManagerApptentiveDelegate?.unreadMessageCount = self.unreadMessageCount
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

    static var thumbnailSize = CGSize(width: 44, height: 44)

    var messageManagerApptentiveDelegate: MessageManagerApptentiveDelegate?
    weak var delegate: MessageManagerDelegate? {
        didSet {
            if let _ = self.delegate {
                // When presenting, trigger a refresh of the message list at the next opportunity.
                self.messageList.lastFetchDate = .distantPast
            } else {
                // When closing, clear out any unsent custom data and/or automated message.
                self.customData = nil
                self.automatedMessage = nil
            }
        }
    }

    var lastDownloadedMessageID: String? {
        self.messageList.lastDownloadedMessageID
    }

    private var messageList: MessageList {
        didSet {
            if self.messageList != oldValue {
                if self.messageList.messages != oldValue.messages {
                    self.delegate?.messageManagerMessagesDidChange(self.messages)
                }

                if self.messageList.draftMessage != oldValue.draftMessage {
                    self.delegate?.messageManagerDraftMessageDidChange(self.messageList.draftMessage)
                }

                self.messageListNeedsSaving = true
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

        self.unreadMessageCount = 0
        notificationCenter.addObserver(self, selector: #selector(payloadSending), name: Notification.Name.payloadSending, object: nil)
        notificationCenter.addObserver(self, selector: #selector(payloadSent), name: Notification.Name.payloadSent, object: nil)
        notificationCenter.addObserver(self, selector: #selector(payloadFailed), name: Notification.Name.payloadFailed, object: nil)
    }

    func load(from loader: Loader) throws {
        if let loadedMessageList = try loader.loadMessages() {
            self.messageList.messages = Self.merge(loadedMessageList.messages, with: self.messageList.messages, attachmentManager: self.attachmentManager)
            self.messageList.draftMessage = loadedMessageList.draftMessage
            self.draftAttachmentNumber = loadedMessageList.draftMessage.attachments.count + 1
            self.messageList.lastFetchDate = max(loadedMessageList.lastFetchDate ?? .distantPast, self.messageList.lastFetchDate ?? .distantPast)
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

    func update(with messagesResponse: MessagesResponse) {
        self.messageList.messages = Self.merge(self.messageList.messages, with: messagesResponse.messages.map { Self.convert(downloadedMessage: $0) }, attachmentManager: self.attachmentManager)
        self.setUnreadMessageCount()
        self.messageList.additionalDownloadableMessagesExist = messagesResponse.hasMore
        self.messageList.lastDownloadedMessageID = messagesResponse.endsWith
        self.messageList.lastFetchDate = Date()
        self.forceMessageDownload = self.messageList.additionalDownloadableMessagesExist
    }

    func setAutomatedMessageBody(_ body: String?) {
        self.automatedMessage = body.flatMap { MessageList.Message(nonce: "automated", body: $0, isAutomated: true) }

        self.delegate?.messageManagerMessagesDidChange(self.messages)
    }

    var draftMessage: MessageList.Message {
        get {
            self.messageList.draftMessage
        }
        set {
            self.messageList.draftMessage = newValue
        }
    }

    func addDraftAttachment(data: Data, name: String?, mediaType: String) throws -> URL {
        guard let attachmentManager = self.attachmentManager else {
            throw MessageError.missingAttachmentManager
        }

        let index = self.messageList.draftMessage.attachments.count
        let filename = self.filename(for: name, mediaType: mediaType)

        let url = try attachmentManager.store(data: data, filename: filename)
        let newAttachment = MessageList.Message.Attachment(contentType: mediaType, filename: filename, storage: .saved(path: url.lastPathComponent), thumbnailData: nil)

        self.messageList.draftMessage.attachments.append(newAttachment)

        AttachmentManager.createThumbnail(of: Self.thumbnailSize, for: url) { result in
            if case .success(let image) = result, let thumbnailData = image.pngData() {
                self.messageList.draftMessage.attachments[index].thumbnailData = thumbnailData
            }
        }

        return url
    }

    func addDraftAttachment(url: URL) throws -> URL {
        guard let attachmentManager = self.attachmentManager else {
            throw MessageError.missingAttachmentManager
        }

        let filename = url.lastPathComponent
        let url = try attachmentManager.store(url: url, filename: filename)
        let newAttachment = MessageList.Message.Attachment(contentType: AttachmentManager.mediaType(for: filename), filename: filename, storage: .saved(path: url.lastPathComponent), thumbnailData: nil)

        let index = self.messageList.draftMessage.attachments.count
        self.messageList.draftMessage.attachments.append(newAttachment)

        AttachmentManager.createThumbnail(of: Self.thumbnailSize, for: url) { result in
            if case .success(let image) = result, let thumbnailData = image.pngData() {
                self.messageList.draftMessage.attachments[index].thumbnailData = thumbnailData
            }
        }

        return url
    }

    func removeDraftAttachment(at index: Int) throws {
        guard let attachmentManager = self.attachmentManager else {
            throw MessageError.missingAttachmentManager
        }

        let attachmentToRemove = self.messageList.draftMessage.attachments[index]
        try attachmentManager.removeStorage(for: attachmentToRemove)
        self.messageList.draftMessage.attachments.remove(at: index)
    }

    func loadAttachment(at index: Int, in message: MessageList.Message, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let attachmentManager = self.attachmentManager else {
            return completion(.failure(MessageError.missingAttachmentManager))
        }

        guard let messageIndex = self.messageList.messages.firstIndex(of: message) else {
            return assertionFailure("Can't find index of message in message list")
        }

        let attachment = message.attachments[index]

        attachmentManager.download(
            attachment,
            completion: { result in
                switch result {
                case .success(let url):
                    self.messageList.messages[messageIndex].attachments[index].storage = .cached(path: url.lastPathComponent)

                    if attachment.thumbnailData == nil {
                        AttachmentManager.createThumbnail(of: Self.thumbnailSize, for: url) { result in
                            if case .success(let image) = result, let thumbnailData = image.pngData() {
                                self.messageList.messages[messageIndex].attachments[index].thumbnailData = thumbnailData
                            }
                        }
                    }
                    completion(.success(url))

                case .failure(let error):
                    completion(.failure(error))
                }
            },
            progress: { progress in
                self.messageList.messages[messageIndex].attachments[index].downloadProgress = Float(progress)
            })
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
            try self.saver?.save(self.messageList)
            self.messageListNeedsSaving = false
        }
    }

    @objc func payloadSending(_ notification: Notification) {
        self.updateStatus(to: .sending, for: notification)
    }

    @objc func payloadSent(_ notification: Notification) {
        self.updateStatus(to: .sent, for: notification)
    }

    @objc func payloadFailed(_ notification: Notification) {
        self.updateStatus(to: .failed, for: notification)
    }

    static func createSaver(containerURL: URL, filename: String, fileManager: FileManager) -> PropertyListSaver<MessageList> {
        return PropertyListSaver<MessageList>(containerURL: containerURL, filename: filename, fileManager: fileManager)
    }

    static func merge(_ existing: [MessageList.Message], with newer: [MessageList.Message], attachmentManager: AttachmentManager?) -> [MessageList.Message] {
        var messagesByNonce = Dictionary(grouping: existing, by: { $0.nonce }).compactMapValues { $0.first }

        for message in newer {
            if let older = messagesByNonce[message.nonce] {
                messagesByNonce[message.nonce] = self.merge(older, with: message, attachmentManager: attachmentManager)
            } else {
                messagesByNonce[message.nonce] = message
            }
        }

        return Array(messagesByNonce.values).sorted(by: { $0.sentDate < $1.sentDate })
    }

    static func merge(_ existing: MessageList.Message, with newer: MessageList.Message, attachmentManager: AttachmentManager?) -> MessageList.Message {
        var result = newer

        if existing.status == .read {
            result.status = .read
        }

        for (index, existingAttachment) in existing.attachments.enumerated() {
            guard result.attachments.count > index else {
                ApptentiveLogger.messages.error("Mismatch of server-side and client-side attachment counts.")
                continue
            }

            if attachmentManager?.cacheFileExists(for: existingAttachment) == true {
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

        return MessageList.Message(nonce: downloadedMessage.nonce, body: downloadedMessage.body, attachments: attachments, sender: sender, sentDate: downloadedMessage.sentDate, status: Self.status(of: downloadedMessage))
    }

    static func status(of downloadedMessage: MessagesResponse.Message) -> MessageList.Message.Status {
        return downloadedMessage.sentFromDevice ? .sent : .unread
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

    private func updateStatus(to status: MessageList.Message.Status, for notification: Notification) {
        guard let payload = notification.userInfo?[PayloadSender.payloadKey] as? Payload else {
            return assertionFailure("Should be able to find payload in payload sender notification's userInfo.")
        }

        if let index = self.messageList.messages.firstIndex(where: { $0.nonce == payload.jsonObject.nonce }) {
            self.messageList.messages[index].status = status

            if status == .sent {
                // Move the attachments from "saved" to "cached" so that the system can jettison them if needed.
                let sentMessage = self.messageList.messages[index]
                do {
                    guard let attachmentManager = self.attachmentManager else {
                        throw MessageError.missingAttachmentManager
                    }

                    for (attachmentIndex, attachment) in sentMessage.attachments.enumerated() {
                        self.messageList.messages[index].attachments[attachmentIndex].storage = try attachmentManager.cacheQueuedAttachment(attachment)
                    }

                } catch let error {
                    ApptentiveLogger.attachments.error("Unable to move queued attachments for payload \(payload.jsonObject.nonce): \(error).")
                }
            }
        }  // else this wasn't a message payload.
    }
}

enum MessageError: Error {
    case missingAttachmentManager
    case emptyBodyAndAttachments
}
