//
//  MessageCenterViewModel.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation

/// A class that describes the data in message center and allows messages to be gathered and transmitted.
public class MessageCenterViewModel {
    weak var interactionDelegate: InteractionDelegate?

    let interaction: Interaction

    /// The list of messages between the consumer and the dashboard.
    var messageList: MessageList?

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

        self.interactionDelegate?.getMessages(completion: { messageList in
            self.messageList = messageList
        })

    }

    /// Adds the message to the array of messages and calls the sendMessage function from the InteractionDelegate  to send the Message to the Apptentive API.
    /// - Parameter message: The message to be sent.
    public func sendMessage(message: Message) {
        self.messageList?.messages.append(message)
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

}
