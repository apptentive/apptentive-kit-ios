//
//  MessageCenterViewModel.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/9/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

/// Represents an object that can be notified of a change to the message list.
public protocol MessageCenterViewModelDelegate: AnyObject {
    func messageCenterViewModelDidBeginUpdates(_: MessageCenterViewModel)
    func messageCenterViewModel(_: MessageCenterViewModel, didInsertSectionsWith sectionIndexes: IndexSet)
    func messageCenterViewModel(_: MessageCenterViewModel, didDeleteSectionsWith sectionIndexes: IndexSet)
    func messageCenterViewModel(_: MessageCenterViewModel, didDeleteRowsAt indexPaths: [IndexPath])
    func messageCenterViewModel(_: MessageCenterViewModel, didUpdateRowsAt indexPaths: [IndexPath])
    func messageCenterViewModel(_: MessageCenterViewModel, didInsertRowsAt indexPaths: [IndexPath])
    func messageCenterViewModel(_: MessageCenterViewModel, didMoveRowsAt indexPathMoves: [(IndexPath, IndexPath)])
    func messageCenterViewModelDidEndUpdates(_: MessageCenterViewModel)

    func messageCenterViewModelMessageListDidLoad(_: MessageCenterViewModel)

    func messageCenterViewModelDraftMessageDidUpdate(_: MessageCenterViewModel)

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToRemoveAttachmentAt index: Int, with error: Error)

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToAddAttachmentWith error: Error)

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToSendMessageWith error: Error)

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFinishAt index: Int, inMessageAt indexPath: IndexPath)

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFailAt index: Int, inMessageAt indexPath: IndexPath, with error: Error)
}

typealias MessageCenterInteractionDelegate = EventEngaging & MessageSending & MessageProviding & AttachmentManaging & ProfileEditing & UnreadMessageUpdating

/// A class that describes the data in message center and allows messages to be gathered and transmitted.
public class MessageCenterViewModel: MessageManagerDelegate {
    let interaction: Interaction
    let interactionDelegate: MessageCenterInteractionDelegate

    static let maxAttachmentCount = 4

    /// The delegate object (typically a view controller) that is notified when messages change.
    weak var delegate: MessageCenterViewModelDelegate?

    /// The title for the message center window.
    public let headingTitle: String

    /// Text for branding watermark, where "Apptentive" is replaced with the logo image.
    public let branding: String?

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

    /// The URL of the image to load into the greeting view.
    public let greetingImageURL: URL

    ///the message describing customer's hours, expected time until response.
    public let statusBody: String

    /// The messages grouped by date, according to the current calendar, sorted with oldest messages last.
    public var groupedMessages: [[Message]]

    /// Whether the initial loading of messages has completed.
    public var hasLoadedMessages: Bool

    /// The size at which to generate thumbnails for attachments.
    public var thumbnailSize = CGSize(width: 44, height: 44) {
        didSet {
            MessageManager.thumbnailSize = self.thumbnailSize
        }
    }

    /// The place holder of the name field of the profile view.
    public let profileNamePlaceholder: String

    /// The place holder of the email field of the profile view.
    public let profileEmailPlaceholder: String

    /// The cancel button text of the profile view.
    public let profileCancelButtonText: String

    /// The save button text of the profile view.
    public let profileSaveButtonText: String

    /// The title of the edit profile view.
    public let editProfileViewTitle: String

    /// The place holder of the name field of the edit profile view.
    public let editProfileNamePlaceholder: String

    /// The place holder of the email field of the edit profile view.
    public let editProfileEmailPlaceholder: String

    /// The cancel button text of the edit profile view.
    public let editProfileCancelButtonText: String

    /// The save button text of the edit profile view.
    public let editProfileSaveButtonText: String

    /// The profile editing rule provided by the dashboard.
    public let profileMode: ProfileMode

    /// The accessibility label for the close button.
    public let closeButtonAccessibilityLabel: String

    /// The accessibility hint for the close button.
    public let closeButtonAccessibilityHint: String

    /// The accessibility label for the profile button.
    public let profileButtonAccessibilityLabel: String

    /// The accessibility hint for the profile button.
    public let profileButtonAccessibilityHint: String

    /// The accessibility label for the send button.
    public let sendButtonAccessibilityLabel: String

    /// The accessibility hint for the send button.
    public let sendButtonAccessibilityHint: String

    /// The accessibility label for the attach button.
    public let attachButtonAccessibilityLabel: String

    /// The accessibility hint for the attach button.
    public let attachButtonAccessibilityHint: String

    /// The title for the attachment options alert.
    public let attachmentOptionsTitle: String

    /// The button label for the images attachment option.
    public let attachmentOptionsImagesButton: String

    /// The button label for the files attachment option.
    public let attachmentOptionsFilesButton: String

    /// The button label for dismissing the attachment options alert.
    public let attachmentOptionsCancelButton: String

    /// The accessibility hint for buttons that show an attachment.
    public let showAttachmentButtonAccessibilityHint: String

    /// The accessibility hint for buttons that download an attachment.
    public let downloadAttachmentButtonAccessibilityHint: String

    // MARK: - Profile

    /// The email address set by the user in the profile views.
    public var emailAddress: String? {
        didSet {
            self.validateProfile()
        }
    }

    /// The name set by the user in the profile views.
    public var name: String? {
        didSet {
            self.validateProfile()
        }
    }

    /// Whether the required elements of the profile (name/email) pass validation.
    public var profileIsValid: Bool

    /// Whether the profile field should be shown alongside the composer.
    public var shouldRequestProfile: Bool

    /// Describes the type of profile editing.
    public enum ProfileMode {
        case optionalEmail
        case requiredEmail
        case hidden
    }

    ///  The index path corresponding to the oldest unread message.
    public var oldestUnreadMessageIndexPath: IndexPath? {
        //oldest group that contains an unread message
        let oldestUnreadMessageGroupSection = self.groupedMessages.firstIndex { messages in
            for message in messages {
                if case .sentFromDashboard(let readStatus) = message.direction, case .unread(_) = readStatus {

                    return true
                }
            }
            return false
        }

        guard let section = oldestUnreadMessageGroupSection else {
            return nil
        }

        //oldest unread message in group
        let messagesInGroup = self.groupedMessages[section]
        let oldestUnreadMessageRow = messagesInGroup.firstIndex { message in
            if case .sentFromDashboard(let readStatus) = message.direction, case .unread(_) = readStatus {
                return true
            }
            return false
        }

        guard let row = oldestUnreadMessageRow else {
            return nil
        }
        let indexPath = IndexPath(row: row, section: section)
        return indexPath

    }

    /// The index path of the newest (last) message.
    public var newestMessageIndexPath: IndexPath? {
        guard let lastGroup = self.groupedMessages.last, lastGroup.count > 0 else {
            return nil
        }

        return IndexPath(row: lastGroup.count - 1, section: self.groupedMessages.count - 1)
    }

    /// Saves changes from the `name` and `emailAddress` properties to the interactionDelegate.
    public func commitProfileEdits() {
        self.interactionDelegate.personName = self.name
        self.interactionDelegate.personEmailAddress = self.emailAddress
    }

    /// Reverts the values of the `name` and `emailAddress` properties to those from the interactionDelegate.
    public func cancelProfileEdits() {
        self.name = self.interactionDelegate.personName
        self.emailAddress = self.interactionDelegate.personEmailAddress
    }

    // MARK: Events

    /// Registers that the Message Center was successfully presented to the user.
    public func launch() {
        self.interactionDelegate.engage(event: .launch(from: self.interaction))
    }

    /// Registers that the Message Center was cancelled by the user.
    public func cancel() {
        self.interactionDelegate.engage(event: .cancel(from: self.interaction))
    }

    // TODO: Add additional events (PBI-2895)

    // MARK: List view

    /// The number of message groups.
    public var numberOfMessageGroups: Int {
        return self.groupedMessages.count
    }

    /// Updates the 'read' status for the specified message.
    public func markMessageAsRead(at indexPath: IndexPath) {
        let message = self.message(at: indexPath)

        if case .sentFromDashboard(let readStatus) = message.direction, case .unread(let id) = readStatus {
            self.interactionDelegate.markMessageAsRead(message.nonce)
            self.interactionDelegate.engage(event: .messageRead(with: id, from: self.interaction))
        }
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

    /// Provides a message for the index path.
    /// - Parameter indexPath: The index path of the message to provide.
    /// - Returns: The message object.
    public func message(at indexPath: IndexPath) -> Message {
        return self.groupedMessages[indexPath.section][indexPath.row]
    }

    /// Downloads the specified attachment and notifies the delegate.
    /// - Parameters:
    ///   - index: The index of the attachment.
    ///   - indexPath: The indexPath of the message.
    public func downloadAttachment(at index: Int, inMessageAt indexPath: IndexPath) {
        let messageViewModel = self.message(at: indexPath)
        guard let managedMessage = self.managedMessages.first(where: { $0.nonce == messageViewModel.nonce }) else {
            self.delegate?.messageCenterViewModel(self, attachmentDownloadDidFailAt: index, inMessageAt: indexPath, with: ApptentiveError.internalInconsistency)
            return
        }

        self.interactionDelegate.loadAttachment(at: index, in: managedMessage) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.delegate?.messageCenterViewModel(self, attachmentDownloadDidFinishAt: index, inMessageAt: indexPath)

                case .failure(let error):
                    self.delegate?.messageCenterViewModel(self, attachmentDownloadDidFailAt: index, inMessageAt: indexPath, with: error)
                }
            }
        }
    }

    // MARK: Editing

    /// The message currently being composed.
    public private(set) var draftMessage: MessageCenterViewModel.Message

    /// The body of the draft message.
    public var draftMessageBody: String? {
        get {
            self.draftMessage.body
        }
        set {
            self.interactionDelegate.setDraftMessageBody(newValue)
        }
    }

    /// The attachments attached to the draft message.
    public var draftAttachments: [MessageCenterViewModel.Message.Attachment] {
        self.draftMessage.attachments
    }

    /// Attaches an image to the draft message.
    /// - Parameters:
    ///  - image: The image to attach.
    ///  - name: The name to associate with the image, if available.
    public func addImageAttachment(_ image: UIImage, name: String?) {
        guard self.canAddAttachment else {
            self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: MessageCenterViewModelError.attachmentCountGreaterThanMax)
            return
        }

        guard let data = image.jpegData(compressionQuality: 0.95) else {
            self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: MessageCenterViewModelError.unableToGetImageData)
            return
        }

        self.interactionDelegate.addDraftAttachment(data: data, name: name, mediaType: "image/jpeg") { result in
            self.finishAddingDraftAttachment(with: result)
        }
    }

    /// Attaches a file to the draft message.
    /// - Parameter sourceURL: The URL of the file to attach.
    public func addFileAttachment(at sourceURL: URL) {
        guard self.canAddAttachment else {
            self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: MessageCenterViewModelError.attachmentCountGreaterThanMax)
            return
        }

        self.interactionDelegate.addDraftAttachment(url: sourceURL) { result in
            self.finishAddingDraftAttachment(with: result)
        }
    }

    /// Removes an attachment from the draft message.
    /// - Parameter index: The index of the attachment to remove.
    public func removeAttachment(at index: Int) {
        self.interactionDelegate.removeDraftAttachment(at: index) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    self.delegate?.messageCenterViewModel(self, didFailToRemoveAttachmentAt: index, with: error)
                }
            }
        }
    }

    /// The difference between the maximum number of attachments and the number
    /// of attachments currently in the draft message.
    public var remainingAttachmentSlots: Int {
        return Self.maxAttachmentCount - self.draftAttachments.count
    }

    /// Whether the Add Attachment button should be enabled.
    public var canAddAttachment: Bool {
        return self.remainingAttachmentSlots > 0
    }

    /// Whether the send button should be enabled.
    public var canSendMessage: Bool {
        return (self.draftAttachments.count > 0 || self.draftMessageBody?.isEmpty == false) && self.profileIsValid
    }

    /// Sends the message to the interaction delegate.
    public func sendMessage() {
        self.interactionDelegate.sendDraftMessage { result in
            if case .failure(let error) = result {
                DispatchQueue.main.async {
                    self.delegate?.messageCenterViewModel(self, didFailToSendMessageWith: error)
                }
            }
        }
    }

    // MARK: - Message Manager Delegate (called on background queue)

    func messageManagerMessagesDidChange(_ managedMessages: [MessageList.Message]) {
        self.managedMessages = managedMessages
        let convertedMessages = managedMessages.compactMap { message -> Message? in
            if message.isHidden {
                return nil
            } else {
                return self.convert(message)
            }
        }

        let groupings = Self.assembleGroupedMessages(messages: convertedMessages)

        if groupings != self.groupedMessages || !self.hasLoadedMessages {
            DispatchQueue.main.async {
                if self.hasLoadedMessages {
                    self.delegate?.messageCenterViewModelDidBeginUpdates(self)
                    self.update(from: self.groupedMessages, to: groupings)
                    self.groupedMessages = groupings
                    self.delegate?.messageCenterViewModelDidEndUpdates(self)
                } else {
                    self.hasLoadedMessages = true
                    self.groupedMessages = groupings
                    self.validateProfile()
                    self.delegate?.messageCenterViewModelMessageListDidLoad(self)
                }
            }
        }
    }

    func messageManagerDraftMessageDidChange(_ managedDraftMessage: MessageList.Message) {
        let result = self.convert(managedDraftMessage)
        DispatchQueue.main.async {
            self.draftMessage = result
            self.delegate?.messageCenterViewModelDraftMessageDidUpdate(self)
        }
    }

    // MARK: - Internal

    let sendingText: String
    let sentText: String
    let failedText: String

    init(configuration: MessageCenterConfiguration, interaction: Interaction, interactionDelegate: MessageCenterInteractionDelegate) {
        self.interaction = interaction
        self.interactionDelegate = interactionDelegate
        self.headingTitle = configuration.title
        self.branding = configuration.branding
        self.composerTitle = configuration.composer.title
        self.composerSendButtonTitle = configuration.composer.sendButton
        self.composerAttachButtonTitle = NSLocalizedString("MC Attach Button Accessibility Label", bundle: .module, value: "Attach", comment: "The accessibility label for the attach button.")
        self.composerPlaceholderText = configuration.composer.hintText
        self.composerCloseConfirmBody = configuration.composer.closeConfirmBody
        self.composerCloseDiscardButtonTitle = configuration.composer.closeDiscardButton
        self.composerCloseCancelButtonTitle = configuration.composer.closeCancelButton
        self.sendingText = configuration.composer.sendStart
        self.sentText = configuration.composer.sendOk
        self.failedText = configuration.composer.sendFail

        self.greetingTitle = configuration.greeting.title
        self.greetingBody = configuration.greeting.body
        self.greetingImageURL = configuration.greeting.imageURL
        self.statusBody = configuration.status.body

        self.sentDateFormatter = DateFormatter()
        self.sentDateFormatter.dateStyle = .short
        self.sentDateFormatter.doesRelativeDateFormatting = true
        self.sentDateFormatter.timeStyle = .short

        self.groupDateFormatter = DateFormatter()
        self.groupDateFormatter.dateStyle = .long
        self.groupDateFormatter.timeStyle = .none

        self.profileMode = MessageCenterViewModel.mode(for: configuration.profile)
        self.editProfileViewTitle = configuration.profile.edit.title
        self.editProfileNamePlaceholder = configuration.profile.edit.nameHint
        self.editProfileEmailPlaceholder = configuration.profile.edit.emailHint
        self.editProfileCancelButtonText = configuration.profile.edit.skipButton
        self.editProfileSaveButtonText = configuration.profile.edit.saveButton
        self.profileNamePlaceholder = configuration.profile.initial.nameHint
        self.profileEmailPlaceholder = configuration.profile.initial.emailHint
        self.profileCancelButtonText = configuration.profile.initial.skipButton
        self.profileSaveButtonText = configuration.profile.initial.saveButton

        self.hasLoadedMessages = false
        self.profileIsValid = false
        self.shouldRequestProfile = false
        self.managedMessages = []
        self.groupedMessages = []
        self.draftMessage = Message(nonce: "", direction: .sentFromDevice(.failed), isAutomated: false, attachments: [], sender: nil, body: nil, sentDate: Date(), statusText: "", accessibilityLabel: "", accessibilityHint: "")

        self.sendButtonAccessibilityLabel = NSLocalizedString("MC Send Button Accessibility Label", bundle: .module, value: "Send", comment: "The accessibility label for the send button.")
        self.sendButtonAccessibilityHint = NSLocalizedString("MC Send Button Accessibility Hint", bundle: .module, value: "Sends the message.", comment: "The accessibility hint for the send button.")
        self.attachButtonAccessibilityLabel = NSLocalizedString("MC Attach Button Accessibility Label", bundle: .module, value: "Attach", comment: "The accessibility label for the attach button.")
        self.attachButtonAccessibilityHint = NSLocalizedString("MC Attach Button Accessibility Hint", bundle: .module, value: "Attaches a photo or file.", comment: "The accessibility hint for the attach button.")
        self.closeButtonAccessibilityLabel = NSLocalizedString("MC Close Button Accessibility Label", bundle: .module, value: "Close", comment: "The accessibility label for the close button.")
        self.closeButtonAccessibilityHint = NSLocalizedString("MC Close Button Accessibility Hint", bundle: .module, value: "Closes Message Center.", comment: "The accessibility hint for the close button.")
        self.profileButtonAccessibilityLabel = NSLocalizedString("MC Profile Button Accessibility Label", bundle: .module, value: "Profile", comment: "The accessibility label for the profile button.")
        self.profileButtonAccessibilityHint = NSLocalizedString("MC Profile Button Accessibility Hint", bundle: .module, value: "Displays the name and email editor.", comment: "The accessibility hint for the profile button.")
        self.showAttachmentButtonAccessibilityHint = NSLocalizedString("Show Attachment Accessibility Hint", bundle: .module, value: "Double-tap to open.", comment: "The accessibility hint for viewing attachments.")
        self.downloadAttachmentButtonAccessibilityHint = NSLocalizedString("Download Attachment Accessibility Hint", bundle: .module, value: "Double-tap to download.", comment: "The accessibility hint for downloading attachments.")
        self.attachmentOptionsTitle = NSLocalizedString("Attachment Options Title", bundle: .module, value: "Select an attachment type.", comment: "The title for the attachment options alert.")
        self.attachmentOptionsFilesButton = NSLocalizedString("Attachment Options Files Button", bundle: .module, value: "Files", comment: "The button label for the images attachment option.")
        self.attachmentOptionsImagesButton = NSLocalizedString("Attachment Options Images Button", bundle: .module, value: "Images", comment: "The button label for the files attachment option.")
        self.attachmentOptionsCancelButton = NSLocalizedString("Attachment Options Cancel Button", bundle: .module, value: "Cancel", comment: "The button label for dismissing the attachment options alert.")

        self.interactionDelegate.messageManagerDelegate = self
        self.interactionDelegate.setAutomatedMessageBody(configuration.automatedMessage?.body)

        self.interactionDelegate.getMessages { messages in
            self.messageManagerMessagesDidChange(messages)
        }

        self.interactionDelegate.getDraftMessage { draftManagedMessage in
            self.messageManagerDraftMessageDidChange(draftManagedMessage)
        }

        self.name = self.interactionDelegate.personName
        self.emailAddress = self.interactionDelegate.personEmailAddress
        self.validateProfile()

        MessageManager.thumbnailSize = self.thumbnailSize
    }

    // Notifies the delegate of inserted, updated, deleted, and moved indexPaths, and inserted and removed sections.
    func update(from old: [[Message]], to new: [[Message]]) {
        let oldSections = old.compactMap { $0.first.flatMap(Self.sectionDate) }
        let newSections = new.compactMap { $0.first.flatMap(Self.sectionDate) }

        let (deletedIndexes, insertedIndexes) = Self.diffSortedCollection(from: oldSections, to: newSections)
        self.delegate?.messageCenterViewModel(self, didInsertSectionsWith: insertedIndexes)
        self.delegate?.messageCenterViewModel(self, didDeleteSectionsWith: deletedIndexes)

        // Build index of indexPath by nonce (old and new)
        let oldIndexPaths = Self.buildIndexPathIndex(from: old)
        let newIndexPaths = Self.buildIndexPathIndex(from: new)

        // Build index of message by nonce (old and new)
        let oldMessages = Self.buildMessageIndex(from: old)
        let newMessages = Self.buildMessageIndex(from: new)

        let allNonces = Set(oldIndexPaths.keys).union(Set(newIndexPaths.keys))

        var updatedIndexPaths = [IndexPath]()
        var movedIndexPaths = [(IndexPath, IndexPath)]()
        var deletedIndexPaths = [IndexPath]()
        var insertedIndexPaths = [IndexPath]()

        for nonce in allNonces {
            let oldIndexPath = oldIndexPaths[nonce]
            let newIndexPath = newIndexPaths[nonce]

            switch (oldIndexPath, newIndexPath) {
            case (.some(let oldIndexPath), .some(let newIndexPath)):
                if oldIndexPath != newIndexPath {
                    movedIndexPaths.append((oldIndexPath, newIndexPath))
                }

                if oldMessages[nonce] != newMessages[nonce] {
                    updatedIndexPaths.append(newIndexPath)
                }

            case (.some(let oldIndexPath), .none):
                deletedIndexPaths.append(oldIndexPath)

            case (.none, .some(let newIndexPath)):
                insertedIndexPaths.append(newIndexPath)

            case (.none, .none):
                apptentiveCriticalError("Should not end up with nil old and new index paths.")
            }
        }

        self.delegate?.messageCenterViewModel(self, didDeleteRowsAt: deletedIndexPaths)
        self.delegate?.messageCenterViewModel(self, didInsertRowsAt: insertedIndexPaths)
        self.delegate?.messageCenterViewModel(self, didUpdateRowsAt: updatedIndexPaths)
        self.delegate?.messageCenterViewModel(self, didMoveRowsAt: movedIndexPaths)
    }

    func validateProfile() {
        self.profileIsValid = Self.isProfileValid(for: self.profileMode, name: self.name, emailAddress: self.emailAddress)

        let hasNoMessages = self.hasLoadedMessages && self.groupedMessages.count == 0
        let missingNameOrEmail = self.name?.isEmpty != false || self.emailAddress?.isEmpty != false
        self.shouldRequestProfile = !self.profileIsValid || (hasNoMessages && missingNameOrEmail && self.profileMode != .hidden)
    }

    static func isProfileValid(for profileMode: ProfileMode, name: String?, emailAddress: String?) -> Bool {
        let emailValid = Self.emailPredicate.evaluate(with: emailAddress)

        switch profileMode {
        case .optionalEmail:
            return emailValid || emailAddress?.isEmpty != false

        case .requiredEmail:
            return emailValid

        case .hidden:
            return true
        }
    }

    static func datesForMessageGroups(in groupedMessages: [[Message]]) -> [Date] {
        return groupedMessages.compactMap { messages in
            messages.first?.sentDate
        }
    }

    // Diffs two sorted arrays of `Comparable`s, returning index sets for deleted and inserted items.
    static func diffSortedCollection<T: Comparable>(from old: [T], to new: [T]) -> (deletedIndexes: IndexSet, insertedIndexes: IndexSet) {
        var oldIndex = 0
        var newIndex = 0
        var deletedIndexes = IndexSet()
        var insertedIndexes = IndexSet()

        while oldIndex < old.count || newIndex < new.count {
            let oldValue = oldIndex < old.count ? old[oldIndex] : nil
            let newValue = newIndex < new.count ? new[newIndex] : nil
            switch (oldValue, newValue) {
            case (.some(let oldValue), .some(let newValue)) where oldValue == newValue:
                oldIndex += 1
                newIndex += 1

            case (.some(let oldValue), .some(let newValue)) where oldValue > newValue:
                insertedIndexes.insert(newIndex)
                newIndex += 1
            case (.none, .some):
                insertedIndexes.insert(newIndex)
                newIndex += 1

            case (.some(let oldValue), .some(let newValue)) where oldValue < newValue:
                deletedIndexes.insert(oldIndex)
                oldIndex += 1
            case (.some, .none):
                deletedIndexes.insert(oldIndex)
                oldIndex += 1

            default:
                oldIndex += 1
                newIndex += 1
            }
        }

        return (deletedIndexes, insertedIndexes)
    }

    static func buildIndexPathIndex(from groupedMessages: [[Message]]) -> [String: IndexPath] {
        var result = [String: IndexPath]()

        for (sectionIndex, group) in groupedMessages.enumerated() {
            for (rowIndex, message) in group.enumerated() {
                result[message.nonce] = IndexPath(row: rowIndex, section: sectionIndex)
            }
        }

        return result
    }

    static func buildMessageIndex(from groupedMessages: [[Message]]) -> [String: Message] {
        return Dictionary(grouping: groupedMessages.flatMap { $0 }, by: { $0.nonce }).compactMapValues { $0.first }
    }

    static func mode(for profile: MessageCenterConfiguration.Profile) -> ProfileMode {
        if profile.require {
            return .requiredEmail
        } else if profile.request {
            return .optionalEmail
        } else {
            return .hidden
        }
    }

    func convert(_ managedMessage: MessageList.Message) -> MessageCenterViewModel.Message {
        let attachments = managedMessage.attachments.enumerated().compactMap { (index, attachment) in
            Message.Attachment(
                fileExtension: AttachmentManager.pathExtension(for: attachment.contentType) ?? "file", thumbnailData: attachment.thumbnailData, localURL: interactionDelegate.urlForAttachment(at: index, in: managedMessage),
                downloadProgress: attachment.downloadProgress)
        }

        let sender = managedMessage.sender.flatMap { Message.Sender(name: $0.name, profilePhotoURL: $0.profilePhoto) }
        let direction: Message.Direction
        let statusText: String
        let sentDateString = sentDateFormatter.string(from: managedMessage.sentDate)

        switch (managedMessage.status, managedMessage.isAutomated) {
        case (_, true):
            direction = .automated
            statusText = "Automated"

        case (.draft, _):
            direction = .sentFromDevice(.draft)
            statusText = "Draft"
        case (.queued, _):
            direction = .sentFromDevice(.queued)
            statusText = self.sendingText
        case (.sending, _):
            direction = .sentFromDevice(.sending)
            statusText = self.sendingText
        case (.sent, _):
            direction = .sentFromDevice(.sent)
            statusText = "\(self.sentText) \(sentDateString)"
        case (.failed, _):
            direction = .sentFromDevice(.failed)
            statusText = self.failedText

        case (.unread, _):
            direction = .sentFromDashboard(.unread(messageID: managedMessage.id))
            statusText = sentDateString
        case (.read, _):
            direction = .sentFromDashboard(.read)
            statusText = sentDateString
        }

        let accessibilityLabel = managedMessage.body ?? NSLocalizedString("No Text", bundle: .module, value: "No Text", comment: "Accessibility label for messages with no text")

        return Message(
            nonce: managedMessage.nonce, direction: direction, isAutomated: managedMessage.isAutomated, attachments: attachments, sender: sender, body: managedMessage.body, sentDate: managedMessage.sentDate,
            statusText: statusText, accessibilityLabel: accessibilityLabel, accessibilityHint: statusText)
    }

    static func assembleGroupedMessages(messages: [Message]) -> [[Message]] {
        var result = [[Message]]()

        let messageDict = Dictionary(grouping: messages) { (message) -> Date in
            Self.sectionDate(for: message)
        }

        let sortedKeys = messageDict.keys.sorted()
        sortedKeys.forEach { (key) in
            let values = messageDict[key]
            result.append(values ?? [])
        }

        return result
    }

    static func sectionDate(for message: Message) -> Date {
        return Calendar.current.startOfDay(for: message.sentDate)
    }

    // MARK: - Private

    private var managedMessages: [MessageList.Message]

    private let sentDateFormatter: DateFormatter

    private let groupDateFormatter: DateFormatter

    private func finishAddingDraftAttachment(with result: Result<URL, Error>) {
        DispatchQueue.main.async {
            if case .failure(let error) = result {
                self.delegate?.messageCenterViewModel(self, didFailToAddAttachmentWith: error)
            }
        }
    }

    private static let emailPredicate = NSPredicate(format: "SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}")
}

extension Event {
    /// Convenience method for a `read` event for Message Center.
    static func messageRead(with id: String?, from interaction: Interaction) -> Self {
        var result = Self(internalName: "read", interaction: interaction)

        result.userInfo = id.flatMap { .messageInfo(ReadMessageInfo(id: $0)) }

        return result
    }
}

struct ReadMessageInfo: Codable, Equatable {
    let id: String

    enum CodingKeys: String, CodingKey {
        case id = "message_id"
    }
}

public enum MessageCenterViewModelError: Error {
    case attachmentCountGreaterThanMax
    case unableToGetImageData
}
