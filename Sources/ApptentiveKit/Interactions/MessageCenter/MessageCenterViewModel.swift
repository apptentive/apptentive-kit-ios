//
//  MessageCenterViewModel.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// Represents an object that can be notified of a change to the message list.
public protocol MessageCenterViewModelDelegate: AnyObject {
    func messageCenterViewModelMessageListDidUpdate(_: MessageCenterViewModel)
}

/// A class that describes the data in message center and allows messages to be gathered and transmitted.
public class MessageCenterViewModel {
    weak var interactionDelegate: InteractionDelegate?
    weak var delegate: MessageCenterViewModelDelegate?

    let interaction: Interaction

    /// The list of messages between the consumer and the dashboard.
    var messageList: MessageList {
        didSet {
            self.assembleGroupedMessages(messages: self.messageList.messages)
            self.delegate?.messageCenterViewModelMessageListDidUpdate(self)
        }
    }

    /// The title for the message center window.
    public let headingTitle: String

    /// Text for branding watermark, where "Apptentive" is replaced with the logo image.
    public let branding: String

    /// The title for the composer window.
    public let composerTitle: String

    ///The title text  for the send button on the composer.
    public let composerSendButtonTitle: String

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

        self.messageList = MessageList()
        self.groupedMessages = [[]]

        self.interactionDelegate?.getMessages(completion: { messageList in
            self.messageList = messageList
            self.assembleGroupedMessages(messages: messageList.messages)
        })
    }

    /// Adds the message to the array of messages and calls the sendMessage function from the InteractionDelegate  to send the Message to the Apptentive API.
    /// - Parameter message: The message to be sent.
    public func sendMessage(message: Message) {
        self.messageList.messages.append(message)
        self.interactionDelegate?.sendMessage(message)
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
}
