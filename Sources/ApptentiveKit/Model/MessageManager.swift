//
//  MessageManager.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/16/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

protocol MessageManagerDelegate: AnyObject {
    // TODO: Pass message array instead of message manager?
    func messageManagerMessagesDidChange(_ messageManager: MessageManager)
}

class MessageManager {
    var foregroundPollingInterval: TimeInterval
    var backgroundPollingInterval: TimeInterval
    var customData: CustomData?

    var notificationCenter: NotificationCenter

    weak var delegate: MessageManagerDelegate? {
        didSet {
            if let _ = self.delegate {
                self.messageList.lastFetchDate = .distantPast
            } else {
                self.customData = nil
            }
        }
    }

    var lastDownloadedMessageID: String? {
        self.messageList.lastDownloadedMessageID
    }

    private(set) var messageList: MessageList {
        didSet {
            if self.messageList != oldValue {
                if self.messageList.messages != oldValue.messages {
                    DispatchQueue.main.async {
                        self.delegate?.messageManagerMessagesDidChange(self)
                    }
                }

                self.messageListNeedsSaving = true
            }
        }
    }

    var draftMessage: OutgoingMessage? {
        get {
            return self.messageList.draftMessage
        }
        set {
            self.messageList.draftMessage = newValue
        }
    }

    var messagesNeedDownloading: Bool {
        let timeSinceLastFetch = Date().timeIntervalSince(self.messageList.lastFetchDate ?? .distantPast)

        return timeSinceLastFetch > self.pollingInterval || self.messageList.additionalDownloadableMessagesExist
    }

    var saver: Saver<MessageList>?

    init(notificationCenter: NotificationCenter) {
        self.messageList = MessageList(messages: [])
        self.messageListNeedsSaving = false
        self.foregroundPollingInterval = 30
        self.backgroundPollingInterval = 300
        self.notificationCenter = notificationCenter

        notificationCenter.addObserver(self, selector: #selector(payloadSending), name: Notification.Name.payloadSending, object: nil)
        notificationCenter.addObserver(self, selector: #selector(payloadSent), name: Notification.Name.payloadSent, object: nil)
        notificationCenter.addObserver(self, selector: #selector(payloadFailed), name: Notification.Name.payloadFailed, object: nil)
    }

    func load(from loader: Loader) throws {
        if let loadedMessageList = try loader.loadMessages() {
            self.messageList.messages = Self.merge(loadedMessageList.messages, with: self.messageList.messages)
            self.messageList.lastFetchDate = max(loadedMessageList.lastFetchDate ?? .distantPast, self.messageList.lastFetchDate ?? .distantPast)
        }
    }

    func update(with messagesResponse: MessagesResponse) {
        self.messageList.messages = Self.merge(self.messageList.messages, with: messagesResponse.messages.map { Self.convert(downloadedMessage: $0) })
        self.messageList.additionalDownloadableMessagesExist = messagesResponse.hasMore
        self.messageList.lastDownloadedMessageID = messagesResponse.endsWith
        self.messageList.lastFetchDate = Date()
    }

    func saveMessagesIfNeeded() throws {
        if self.messageListNeedsSaving {
            try self.saver?.save(self.messageList)
            self.messageListNeedsSaving = false
        }
    }

    func addQueuedMessage(_ message: OutgoingMessage, nonce: String, sentDate: Date) {
        self.messageList.messages.append(Self.convert(outgoingMessage: message, nonce: nonce, sentDate: sentDate))
    }

    @objc private func payloadSending(_ notification: Notification) {
        self.updateStatus(to: .sending, for: notification)
    }

    @objc func payloadSent(_ notification: Notification) {
        self.updateStatus(to: .sent, for: notification)
    }

    @objc func payloadFailed(_ notification: Notification) {
        self.updateStatus(to: .failed, for: notification)
    }

    private func updateStatus(to status: MessageList.Message.Status, for notification: Notification) {
        guard let payload = notification.userInfo?[PayloadSender.payloadKey] as? Payload
        else {
            return assertionFailure("Should be able to find payload in payload sender notification's userInfo.")
        }

        if let index = self.messageList.messages.firstIndex(where: { $0.nonce == payload.jsonObject.nonce }) {
            self.messageList.messages[index].status = status
        }  // else this probably wasn't a message payload.
    }

    static func createSaver(containerURL: URL, filename: String, fileManager: FileManager) -> PropertyListSaver<MessageList> {
        return PropertyListSaver<MessageList>(containerURL: containerURL, filename: filename, fileManager: fileManager)
    }

    static func merge(_ existing: [MessageList.Message], with newer: [MessageList.Message]) -> [MessageList.Message] {
        var messagesByNonce = Dictionary(grouping: existing, by: { $0.nonce }).compactMapValues { $0.first }

        for message in newer {
            if let older = messagesByNonce[message.nonce] {
                messagesByNonce[message.nonce] = Self.merge(older, with: message)
            } else {
                messagesByNonce[message.nonce] = message
            }
        }

        return Array(messagesByNonce.values).sorted(by: { $0.sentDate < $1.sentDate })
    }

    static func merge(_ existing: MessageList.Message, with newer: MessageList.Message) -> MessageList.Message {
        var result = newer

        if existing.status == .read {
            result.status = .read
        }

        return result
    }

    static func convert(downloadedMessage: MessagesResponse.Message) -> MessageList.Message {
        let attachments = downloadedMessage.attachments.map { attachment in
            MessageList.Message.Attachment(contentType: attachment.contentType, filename: attachment.filename, url: attachment.url, size: attachment.size)
        }

        let sender = downloadedMessage.sender.flatMap { sender in
            MessageList.Message.Sender(name: sender.name, profilePhoto: sender.profilePhoto)
        }

        return MessageList.Message(nonce: downloadedMessage.nonce, body: downloadedMessage.body, attachments: attachments, sender: sender, sentDate: downloadedMessage.sentDate, status: Self.status(of: downloadedMessage))
    }

    static func convert(outgoingMessage: OutgoingMessage, nonce: String, sentDate: Date) -> MessageList.Message {
        let attachments = outgoingMessage.attachments.map { attachment in
            // TODO: better filename fallback? Or make filename non-optional?
            MessageList.Message.Attachment(contentType: attachment.contentType, filename: attachment.filename ?? "Attachment", url: nil, size: nil)
        }

        return MessageList.Message(nonce: nonce, body: outgoingMessage.body, attachments: attachments, sender: nil, sentDate: sentDate, status: .queued)
    }

    static func status(of downloadedMessage: MessagesResponse.Message) -> MessageList.Message.Status {
        switch (downloadedMessage.isHidden ?? false, downloadedMessage.isAutomated ?? false, downloadedMessage.sentByLocalUser) {
        case (true, _, _):
            return .hidden
        case (false, true, true):
            return .automated
        case (false, false, true):
            return .sent
        case (false, false, false):
            return .unread
        case (false, true, false):
            return .unknown
        }
    }

    private var messageListNeedsSaving: Bool

    private var pollingInterval: TimeInterval {
        self.delegate != nil ? self.foregroundPollingInterval : self.backgroundPollingInterval
    }
}
