//
//  MessageCenterViewModel.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import UIKit

/// Represents an object that can be notified of a change to the message list.
public protocol MessageCenterViewModelDelegate: AnyObject {
    func messageCenterViewModelMessageListDidUpdate(_: MessageCenterViewModel)

    func messageCenterViewModelCanAddAttachmentDidUpdate(_: MessageCenterViewModel)

    func messageCenterViewModelCanSendMessageDidUpdate(_: MessageCenterViewModel)
}

/// A class that describes the data in message center and allows messages to be gathered and transmitted.
public class MessageCenterViewModel: MessageManagerDelegate {
    // MARK: Message Manager Delegate
    func messageManagerMessagesDidChange(_ messageManager: MessageManager) {
        let messageViewModels = messageManager.messageList.messages.map { (message: MessageList.Message) -> Message in
            let attachments = message.attachments.compactMap { attachment -> Message.Attachment? in
                guard let url = attachment.url else {
                    return nil
                }

                return Message.Attachment(mediaType: attachment.contentType, filename: attachment.filename, url: url)
            }
            let sender = message.sender.flatMap { Message.Sender(name: $0.name, profilePhotoURL: $0.profilePhoto) }

            return Message(
                sentByLocalUser: Self.sentByLocalUser(message), isAutomated: message.status == .automated, isHidden: message.status == .hidden, attachments: attachments, sender: sender, body: message.body, sentDate: message.sentDate, wasRead: false)
        }

        self.assembleGroupedMessages(messages: messageViewModels)

        self.delegate?.messageCenterViewModelMessageListDidUpdate(self)
    }

    static func sentByLocalUser(_ message: MessageList.Message) -> Bool {
        switch message.status {
        case .queued, .sending, .sent:
            return true
        default:
            return false
        }
    }

    static let maxAttachmentCount = 4
    weak var interactionDelegate: InteractionDelegate?
    weak var delegate: MessageCenterViewModelDelegate?

    let interaction: Interaction

    /// The title for the message center window.
    public let headingTitle: String

    /// Text for branding watermark, where "Apptentive" is replaced with the logo image.
    public let branding: String

    /// The title for the composer window.
    public let composerTitle: String

    /// The title text for the send button on the composer.
    public let composerSendButtonTitle: String

    /// The title text for the attach button in the composer.
    public let composerAttachButtonTitle: String

    /// The hint text displayed in the text box for the composer.
    public let composerPlaceholderText: String

    /// The text for composer close confirmation dialog.
    public let composerCloseConfirmBody: String

    /// The text for discard message button.
    public let composerCloseDiscardButtonTitle: String

    /// The text for the composer cancel button.
    public let composerCloseCancelButtonTitle: String

    /// The title text for the greeting message.
    public let greetingTitle: String

    /// The text body for the greeting message.
    public let greetingBody: String

    ///the message describing customer's hours, expected time until response.
    public let statusBody: String

    /// The introductory message added to conversation after consumer's message is sent.
    public let automatedMessageBody: String?

    /// The messages grouped by date, according to the current calendar, sorted with oldest messages last.
    public var groupedMessages: [[Message]]

    /// The formatter for the sent date labels.
    public var sentDateFormatter: DateFormatter

    /// The formatter for the group headers.
    public var groupDateFormatter: DateFormatter

    init(configuration: MessageCenterConfiguration, interaction: Interaction, delegate: InteractionDelegate) {
        self.interactionDelegate = delegate
        self.interaction = interaction
        self.headingTitle = configuration.title
        self.branding = configuration.branding
        self.composerTitle = configuration.composer.title
        self.composerSendButtonTitle = configuration.composer.sendButton
        self.composerAttachButtonTitle = configuration.composer.attachmentButton ?? "Add Attachment"
        self.composerPlaceholderText = configuration.composer.hintText
        self.composerCloseConfirmBody = configuration.composer.closeConfirmBody
        self.composerCloseDiscardButtonTitle = configuration.composer.closeDiscardButton
        self.composerCloseCancelButtonTitle = configuration.composer.closeCancelButton
        self.greetingTitle = configuration.greeting.title
        self.greetingBody = configuration.greeting.body
        self.statusBody = configuration.status.body
        self.automatedMessageBody = configuration.automatedMessage?.body ?? "We're sorry to hear that you don't love this app! Is there anything we could do to make it better?"

        self.sentDateFormatter = DateFormatter()
        self.sentDateFormatter.dateStyle = .none
        self.sentDateFormatter.timeStyle = .short

        self.groupDateFormatter = DateFormatter()
        self.groupDateFormatter.dateStyle = .long
        self.groupDateFormatter.timeStyle = .none

        self.groupedMessages = []

        if let messageManager = self.interactionDelegate?.messageManager {
            messageManager.delegate = self
            self.draftMessage = messageManager.draftMessage
            self.messageManagerMessagesDidChange(messageManager)
        }
    }

    deinit {
        self.interactionDelegate?.messageManager.draftMessage = self.draftMessage
        self.interactionDelegate?.messageManager.delegate = nil
    }

    /// Adds the message to the array of messages and calls the sendMessage function from the InteractionDelegate  to send the Message to the Apptentive API.
    /// - Throws: If the message has no body or attachments.
    public func sendMessage() throws {
        guard let message = self.draftMessage else {
            throw MessageCenterViewModelError.messageHasNoBodyOrAttachments
        }

        self.interactionDelegate?.sendMessage(message)

        self.draftMessage = nil
    }

    /// Registers that the Message Center was successfully presented to the user.
    public func launch() {
        self.interactionDelegate?.engage(event: .launch(from: self.interaction))
    }

    /// Registers that the Message Center was cancelled by the user.
    public func cancel() {
        self.interactionDelegate?.engage(event: .cancel(from: self.interaction))
    }

    /// The number of message groups.
    public var numberOfMessageGroups: Int {
        return self.groupedMessages.count
    }

    /// Returns the number of messages in the specified group.
    /// - Parameter index: the index of the message group.
    /// - Returns: the number of messages in the group.
    public func numberOfMessagesInGroup(at index: Int) -> Int {
        return self.groupedMessages[index].count
    }

    /// The date string for the message group, according to the current calendar.
    /// - Parameter index: The index of the group.
    /// - Returns: A string formatted with the date of messages in the group.
    public func dateStringForMessagesInGroup(at index: Int) -> String? {
        if self.groupedMessages[index].count > 0 {
            return self.groupDateFormatter.string(from: self.groupedMessages[index].first?.sentDate ?? Date())
        } else {
            return nil
        }
    }

    /// Returns whether the message at the specified index path is inbound (sent from the Apptentive dashboard).
    /// - Parameter indexPath: the index path of the message.
    /// - Returns: whether the message is inbound.
    public func sentByLocalUser(at indexPath: IndexPath) -> Bool {
        return self.message(at: indexPath).sentByLocalUser
    }

    /// Returns the text of the message at the specified index path.
    /// - Parameter indexPath: the index path of the message.
    /// - Returns: the text of the message.
    public func messageText(at indexPath: IndexPath) -> String? {
        return self.message(at: indexPath).body
    }

    /// Returns the date that the message at the specified index path was sent.
    /// - Parameter indexPath: the index path of the message.
    /// - Returns: a human-readable string of the date that the message was sent.
    public func sentDateString(at indexPath: IndexPath) -> String {
        return self.sentDateFormatter.string(from: self.message(at: indexPath).sentDate)
    }

    /// Returns the name of the sender (if any) of the message at the specified index path.
    /// - Parameter indexPath: the index path of the message.
    /// - Returns: The name of the sender, if any.
    public func senderName(at indexPath: IndexPath) -> String? {
        return self.message(at: indexPath).sender?.name
    }

    /// Returns a URL pointing to the an image for the sender (if any) of the message at the specified index path.
    /// - Parameter indexPath: the index path of the message.
    /// - Returns: A URL for the image, if one is available.
    public func senderImageURL(at indexPath: IndexPath) -> URL? {
        return self.message(at: indexPath).sender?.profilePhotoURL
    }

    /// Attaches an image to the draft message.
    /// - Parameter image: The image to attach.
    /// - Throws: If attachment count greater than max or unable to get data from the image.
    public func addImageAttachment(_ image: UIImage) throws {
        guard self.canAddAttachment else {
            throw MessageCenterViewModelError.attachmentCountGreaterThanMax
        }

        guard let data = image.jpegData(compressionQuality: 0.95) else {
            throw MessageCenterViewModelError.unableToGetJPEGData
        }

        // ItemProvider calls its completion block off the main queue, so jump to the main queue for the UI updates.
        DispatchQueue.main.async {
            self.addAttachment(filename: self.getAttachmentFilename(), data: data, mediaType: "image/jpeg")
        }
    }

    /// Attaches a file to the draft message.
    /// - Parameter at: The URL of the file to attach.
    /// - Throws: If attachment count is greater than the max allowed.
    public func addFileAttachment(at: URL) throws {
        guard self.canAddAttachment else {
            throw MessageCenterViewModelError.attachmentCountGreaterThanMax
        }

        // Read the data into memory on a background queue.
        DispatchQueue.global(qos: .utility).async {
            if let data = try? Data(contentsOf: at) {
                // Perform UI updates on the main queue.
                DispatchQueue.main.async {
                    self.addAttachment(filename: self.getAttachmentFilename(), data: data, mediaType: self.mediaType(for: at))
                }
            } else {
                ApptentiveLogger.default.error("Unable to get data for attachment file at \(at).")
            }
        }
    }

    /// Removes an attachment from the draft message.
    /// - Parameter index: The index of the attachment to remove.
    /// - Throws: If the attachment index is out of range.
    public func removeAttachment(at index: Int) throws {
        guard let draftMessage = self.draftMessage, draftMessage.attachments.count > index else {
            throw MessageCenterViewModelError.attachmentIndexOutOfRange
        }

        self.draftMessage?.attachments.remove(at: index)
    }

    /// The body of the draft message.
    public var messageBody: String? {
        get {
            self.draftMessage?.body
        }
        set {
            if self.draftMessage == nil {
                self.draftMessage = OutgoingMessage()
            }

            self.draftMessage?.body = newValue

            self.delegate?.messageCenterViewModelCanSendMessageDidUpdate(self)
        }
    }

    /// The difference between the maximum number of attachments and the number
    /// of attachments currently in the draft message.
    var remainingAttachmentSlots: Int {
        return Self.maxAttachmentCount - (self.draftMessage?.attachments.count ?? 0)
    }

    /// Whether the Add Attachment button should be enabled.
    var canAddAttachment: Bool {
        return self.remainingAttachmentSlots > 0
    }

    /// Whether the send button should be enabled.
    var canSendMessage: Bool {
        return self.draftMessage?.attachments.isEmpty == false || self.draftMessage?.body?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    // MARK: - Private

    private var draftMessage: OutgoingMessage?

    private func addAttachment(filename: String, data: Data, mediaType: String) {
        if self.draftMessage == nil {
            self.draftMessage = OutgoingMessage()
        }

        self.draftMessage?.attachments.append(Payload.Attachment(contentType: mediaType, filename: filename, contents: .data(data)))

        self.delegate?.messageCenterViewModelCanSendMessageDidUpdate(self)
        self.delegate?.messageCenterViewModelCanAddAttachmentDidUpdate(self)
    }

    private func message(at indexPath: IndexPath) -> Message {
        return self.groupedMessages[indexPath.section][indexPath.row]
    }

    private func assembleGroupedMessages(messages: [Message]) {
        self.groupedMessages.removeAll()

        let messageDict = Dictionary(grouping: messages) { (message) -> Date in
            Calendar.current.startOfDay(for: message.sentDate)
        }

        let sortedKeys = messageDict.keys.sorted()
        sortedKeys.forEach { (key) in
            let values = messageDict[key]
            self.groupedMessages.append(values ?? [])
        }
    }

    private func mediaType(for url: URL) -> String {
        let pathExtension = url.pathExtension

        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }

    private func getAttachmentFilename() -> String {
        guard let draftMessage = self.draftMessage else {
            return "Attachment"
        }

        return "Attachment \(draftMessage.attachments.count + 1)"
    }
}

public enum MessageCenterViewModelError: Error {
    case attachmentCountGreaterThanMax
    case attachmentIndexOutOfRange
    case messageHasNoBodyOrAttachments
    case unableToGetJPEGData
}
