//
//  MessageViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import PhotosUI
import QuickLook
import UIKit

class MessageViewController: UITableViewController, UITextViewDelegate, MessageCenterViewModelDelegate,
    PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate,
    QLPreviewControllerDelegate, QLPreviewControllerDataSource
{
    let viewModel: MessageCenterViewModel
    let headerView: GreetingHeaderView
    let messageListFooterView: MessageListFooterView
    let composeContainerView: MessageCenterComposeContainerView
    let profileFooterView: ProfileFooterView
    let messageReceivedCellID = "MessageCellReceived"
    let messageSentCellID = "MessageSentCell"

    init(viewModel: MessageCenterViewModel) {
        self.composeContainerView = MessageCenterComposeContainerView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 44)))
        self.headerView = GreetingHeaderView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 320)))
        self.messageListFooterView = MessageListFooterView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 88)))
        self.profileFooterView = ProfileFooterView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 115)))
        self.viewModel = viewModel
        super.init(style: .grouped)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        self.viewModel.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Controller Overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = .apptentiveClose
        self.navigationItem.rightBarButtonItem?.target = self
        self.navigationItem.rightBarButtonItem?.action = #selector(closeMessageCenter)
        self.navigationItem.title = self.viewModel.headingTitle

        self.navigationItem.leftBarButtonItem = .apptentiveProfileEdit
        self.navigationItem.leftBarButtonItem?.target = self
        self.navigationItem.leftBarButtonItem?.action = #selector(openProfileEditView)

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 120
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.register(MessageReceivedCell.self, forCellReuseIdentifier: self.messageReceivedCellID)
        self.tableView.register(MessageSentCell.self, forCellReuseIdentifier: self.messageSentCellID)

        self.composeContainerView.composeView.textView.delegate = self
        self.composeContainerView.composeView.textView.accessibilityLabel = self.viewModel.composerTitle
        self.composeContainerView.composeView.textView.accessibilityHint = self.viewModel.composerPlaceholderText
        self.composeContainerView.composeView.placeholderLabel.text = self.viewModel.composerPlaceholderText
        self.composeContainerView.composeView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        self.composeContainerView.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
        self.composeContainerView.composeView.sendButton.accessibilityLabel = self.viewModel.composerSendButtonTitle

        self.composeContainerView.composeView.attachmentButton.addTarget(self, action: #selector(addAttachment(_:)), for: .touchUpInside)
        self.composeContainerView.composeView.attachmentButton.isEnabled = self.viewModel.canAddAttachment
        self.composeContainerView.composeView.attachmentButton.accessibilityLabel = self.viewModel.composerAttachButtonTitle

        self.composeContainerView.composeView.attachmentStackView.tag = Self.draftMessageTag
        for index in 0..<MessageCenterViewModel.maxAttachmentCount {
            let attachmentView = DraftAttachmentView(frame: .zero)
            attachmentView.isHidden = true
            attachmentView.closeButton.addTarget(self, action: #selector(removeDraftAttachment(_:)), for: .touchUpInside)
            attachmentView.gestureRecognizer.addTarget(self, action: #selector(showAttachment(_:)))
            attachmentView.tag = index
            self.composeContainerView.composeView.attachmentStackView.addArrangedSubview(attachmentView)
        }

        self.tableView.tableHeaderView = self.headerView
        self.tableView.accessibilityLabel = self.viewModel.headingTitle

        self.headerView.greetingTitleLabel.text = self.viewModel.greetingTitle
        self.headerView.greetingBodyLabel.text = self.viewModel.greetingBody
        self.headerView.brandingImageView.url = self.viewModel.greetingImageURL

        self.messageListFooterView.statusTextLabel.text = self.viewModel.statusBody

        self.profileFooterView.nameTextField.text = self.viewModel.name
        self.profileFooterView.nameTextField.placeholder = self.viewModel.profileNamePlaceholder
        self.profileFooterView.nameTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)

        self.profileFooterView.emailTextField.text = self.viewModel.emailAddress
        self.profileFooterView.emailTextField.placeholder = self.viewModel.profileEmailPlaceholder
        self.profileFooterView.emailTextField.addTarget(self, action: #selector(textFieldChanged(_:)), for: .editingChanged)
        self.profileFooterView.emailTextField.addTarget(self, action: #selector(textFieldDidEndEditing(_:)), for: .editingDidEnd)

        self.updateProfileValidation(strict: self.viewModel.emailAddress?.isEmpty != true)
        self.tableView.separatorColor = .clear

        self.viewModel.delegate = self

        self.messageCenterViewModelDraftMessageDidUpdate(self.viewModel)

        if self.viewModel.hasLoadedMessages {
            self.messageCenterViewModelMessageListDidLoad(self.viewModel)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate { context in
            self.sizeHeaderFooterViews()
        } completion: { _ in
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !self.initialScrollToBottomCompleted {
            self.sizeHeaderFooterViews()
            self.scrollToBottom(false)
        }
    }

    // MARK: Input accessory view

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var inputAccessoryView: UIView? {
        return self.composeContainerView
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfMessageGroups
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfMessagesInGroup(at: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        let message = self.viewModel.message(at: indexPath)

        switch message.direction {
        case .sentFromDevice:
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageSentCellID, for: indexPath)

        case .sentFromDashboard:
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageReceivedCellID, for: indexPath)
        }

        cell.selectionStyle = .none

        switch (message.direction, cell) {
        case (.sentFromDashboard, let receivedCell as MessageReceivedCell):
            receivedCell.messageText.text = message.body
            receivedCell.dateLabel.text = message.statusText
            receivedCell.senderLabel.text = message.sender?.name
            receivedCell.profileImageView.url = message.sender?.profilePhotoURL
            self.updateStackView(receivedCell.attachmentStackView, with: message, at: indexPath)
            receivedCell.accessibilityElements = [receivedCell.senderLabel, receivedCell.messageText, receivedCell.attachmentStackView, receivedCell.dateLabel]

        case (.sentFromDevice, let sentCell as MessageSentCell):
            sentCell.messageText.text = message.body
            sentCell.statusLabel.text = message.statusText
            self.updateStackView(sentCell.attachmentStackView, with: message, at: indexPath)
            sentCell.accessibilityElements = [sentCell.messageText, sentCell.attachmentStackView, sentCell.statusLabel]

        default:
            assertionFailure("Cell type doesn't match inbound value")
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.viewModel.dateStringForMessagesInGroup(at: section)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == tableView.numberOfSections - 1 && indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1 {
            self.viewModel.updateUnreadMessages()
        }
    }

    // MARK: - Text View Delegate

    func textViewDidChange(_ textView: UITextView) {
        self.sizeComposeTextView()

        self.viewModel.draftMessageBody = textView.text
        self.composeContainerView.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.viewModel.addImageAttachment(image, name: nil)
        } else {
            ApptentiveLogger.default.error("UIImagePickerController failed to provide picked image.")
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    // MARK: - PHPickerViewControllerDelegate

    @available(iOS 14, *)
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { (object, error) in
                if let error = error {
                    ApptentiveLogger.default.debug("Error selecting images from PHPicker: \(error).")
                }

                guard let image = object as? UIImage else {
                    ApptentiveLogger.default.error("PHPickerViewController failed to provide picked image.")
                    return
                }

                self.viewModel.addImageAttachment(image, name: result.itemProvider.suggestedName)
            }
        }
    }

    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        controller.dismiss(animated: true)
        self.viewModel.addFileAttachment(at: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true, completion: nil)
    }

    // MARK: - QuickLook Preview Controller Data Source

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return self.previewedMessage?.attachments.count ?? 0
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard self.previewedMessage?.attachments.count ?? 0 > index, let previewedAttachment = previewedMessage?.attachments[index] else {
            return MessageCenterViewModel.Message.Attachment(fileExtension: nil, thumbnailData: nil, localURL: nil, downloadProgress: 0)
        }

        return previewedAttachment
    }

    // MARK: - QuickLook Preview Controller Delegate

    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        self.previewedMessage = nil
    }

    func previewController(_ controller: QLPreviewController, transitionViewFor item: QLPreviewItem) -> UIView? {
        if let activeStackView = self.previewSourceView?.superview as? UIStackView {
            self.previewSourceView = activeStackView.arrangedSubviews[controller.currentPreviewItemIndex]
        }

        return self.previewSourceView
    }

    // MARK: - View Model Delegate

    func messageCenterViewModelDidBeginUpdates(_: MessageCenterViewModel) {
        self.tableView.beginUpdates()
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didInsertSectionsWith sectionIndexes: IndexSet) {
        self.tableView.insertSections(sectionIndexes, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didDeleteSectionsWith sectionIndexes: IndexSet) {
        self.tableView.deleteSections(sectionIndexes, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didDeleteRowsAt indexPaths: [IndexPath]) {
        self.tableView.deleteRows(at: indexPaths, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didUpdateRowsAt indexPaths: [IndexPath]) {
        self.tableView.reloadRows(at: indexPaths, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didInsertRowsAt indexPaths: [IndexPath]) {
        self.tableView.insertRows(at: indexPaths, with: .automatic)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didMoveRowsAt indexPathMoves: [(IndexPath, IndexPath)]) {
        for move in indexPathMoves {
            self.tableView.moveRow(at: move.0, to: move.1)
        }
    }

    func messageCenterViewModelDidEndUpdates(_: MessageCenterViewModel) {
        self.tableView.endUpdates()

        self.scrollToBottom(true)
    }

    func messageCenterViewModelMessageListDidLoad(_: MessageCenterViewModel) {
        self.updateFooter()

        self.tableView.reloadData()

        if self.isViewLoaded {
            self.scrollToBottom(false)
        }
    }

    func postAccessibilityNotificationForLastMessage() {
        if self.viewModel.numberOfMessageGroups > 0 && self.viewModel.numberOfMessagesInGroup(at: self.viewModel.numberOfMessageGroups - 1) > 0 {
            let lastIndexPath = IndexPath(row: self.viewModel.numberOfMessagesInGroup(at: self.viewModel.numberOfMessageGroups - 1) - 1, section: self.viewModel.numberOfMessageGroups - 1)
            let lastTableViewCell = self.tableView.cellForRow(at: lastIndexPath)

            if let receivedCell = lastTableViewCell as? MessageReceivedCell {
                UIAccessibility.post(notification: .layoutChanged, argument: receivedCell.messageText)
            } else if let sentCell = lastTableViewCell as? MessageSentCell {
                UIAccessibility.post(notification: .layoutChanged, argument: sentCell.messageText)
            }
        }
    }

    func messageCenterViewModelDraftMessageDidUpdate(_: MessageCenterViewModel) {
        self.composeContainerView.composeView.textView.text = self.viewModel.draftMessageBody
        self.composeContainerView.composeView.textViewDidChange()
        self.sizeComposeTextView()

        self.updateDraftAttachments()

        self.composeContainerView.composeView.attachmentButton.isEnabled = viewModel.canAddAttachment
        self.composeContainerView.composeView.sendButton.isEnabled = viewModel.canSendMessage
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToRemoveAttachmentAt index: Int, with error: Error) {
        ApptentiveLogger.default.error("Unable to remove attachment at index \(index): \(error).")
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToAddAttachmentWith error: Error) {
        ApptentiveLogger.default.error("Unable to add attachment: \(error).")
    }

    func messageCenterViewModel(_: MessageCenterViewModel, didFailToSendMessageWith error: Error) {
        ApptentiveLogger.default.error("Unable to send message: \(error).")
    }

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFinishAt index: Int, inMessageAt indexPath: IndexPath) {
        self.tableView.reloadRows(at: [indexPath], with: .fade)
    }

    func messageCenterViewModel(_: MessageCenterViewModel, attachmentDownloadDidFailAt index: Int, inMessageAt indexPath: IndexPath, with error: Error) {
        ApptentiveLogger.default.error("Unable to download attachment #\(index) in row \(indexPath.row) of section \(indexPath.section).")
    }

    // MARK: - Notifications

    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardRect = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval
        else {
            ApptentiveLogger.interaction.warning("Expected keyboard frame in notification")
            return
        }

        // This is only needed because we want to keep the bottom of the message list fixed WRT the bottom of the table view
        UIView.animate(withDuration: animationDuration) {
            self.tableView.contentOffset = CGPoint(x: 0, y: self.tableView.contentOffset.y + keyboardRect.height - self.tableView.adjustedContentInset.bottom)
        }
    }

    // MARK: - Targets

    @objc func openProfileEditView() {
        let profileViewController = EditProfileViewController(viewModel: self.viewModel)

        let navigationController = ApptentiveNavigationController(rootViewController: profileViewController)
        if #available(iOS 13.0, *) {
            navigationController.isModalInPresentation = true
        }
        self.present(navigationController, animated: true, completion: nil)
    }

    @objc func closeMessageCenter() {
        self.viewModel.cancel()
        self.dismiss()
    }

    @objc func addAttachment(_ sender: UIButton) {
        self.showAttachmentOptions(sourceView: sender)
    }

    @objc func sendMessage() {
        self.viewModel.sendMessage()

        self.composeContainerView.composeView.textView.resignFirstResponder()
        self.tableView.tableFooterView = self.messageListFooterView
        self.navigationItem.leftBarButtonItem?.isEnabled = true
    }

    @objc func removeDraftAttachment(_ sender: UIButton) {
        let index = sender.superview?.tag ?? 0

        self.viewModel.removeAttachment(at: index)
    }

    @objc func downloadAttachment(_ sender: UITapGestureRecognizer) {
        let view = sender.view
        let index = view?.tag ?? 0
        let indexPath = self.indexPath(forTag: view?.superview?.tag ?? 0)

        self.viewModel.downloadAttachment(at: index, inMessageAt: indexPath)
    }

    @objc func showAttachment(_ sender: UITapGestureRecognizer) {
        let view = sender.view
        let index = view?.tag ?? 0
        let superViewTag = view?.superview?.tag ?? 0

        let previewController = QLPreviewController()
        previewController.dataSource = self
        previewController.delegate = self
        previewController.currentPreviewItemIndex = index

        if superViewTag == Self.draftMessageTag {
            self.previewedMessage = self.viewModel.draftMessage
        } else {
            let indexPath = self.indexPath(forTag: superViewTag)
            self.previewedMessage = self.viewModel.message(at: indexPath)
        }
        self.previewSourceView = view

        // Have to enclose this in a navigation controller as the swipe-down-to-dismiss
        // doesn't correctly restore this view controller (seems to be related to inputAccessoryView)
        let navigationController = UINavigationController(rootViewController: previewController)
        navigationController.modalPresentationStyle = .fullScreen
        previewController.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeAttachmentPreview(_:)))

        self.present(navigationController, animated: true)
    }

    @objc func closeAttachmentPreview(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true)
    }

    @objc func textFieldChanged(_ sender: UITextField) {
        switch sender.tag {
        case 0:
            self.viewModel.name = sender.text

        case 1:
            self.viewModel.emailAddress = sender.text

        default:
            assertionFailure("Expected 0 or 1 for text field tag.")
        }

        self.composeContainerView.composeView.sendButton.isEnabled = self.viewModel.canSendMessage

        self.updateProfileValidation(strict: false)
    }

    @objc private func textFieldDidEndEditing(_ sender: UITextField) {
        self.composeContainerView.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
        self.updateProfileValidation(strict: true)
    }

    // MARK: - Private

    private var initialScrollToBottomCompleted = false

    private static let draftMessageTag: Int = 0xFFFF

    private var previewedMessage: MessageCenterViewModel.Message?
    private var previewSourceView: UIView?

    private func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func updateProfileValidation(strict: Bool) {
        if self.viewModel.profileIsValid || !strict {
            self.profileFooterView.emailTextField.layer.borderColor = UIColor.apptentiveMessageTextViewBorder.cgColor
        } else {
            self.profileFooterView.emailTextField.layer.borderColor = UIColor.apptentiveError.cgColor
        }

        self.composeContainerView.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
    }

    private func scrollToBottom(_ animated: Bool) {
        self.initialScrollToBottomCompleted = true
        self.tableView.layoutIfNeeded()

        if self.tableView.bounds.height > self.tableView.contentSize.height + self.tableView.adjustedContentInset.bottom {
            self.tableView.setContentOffset(.zero, animated: animated)
        } else {
            let verticalContentOffset = self.tableView.contentSize.height + self.tableView.adjustedContentInset.bottom - self.tableView.bounds.height
            self.tableView.setContentOffset(CGPoint(x: 0, y: verticalContentOffset), animated: animated)
        }

        self.postAccessibilityNotificationForLastMessage()
    }

    private func updateFooter() {
        if self.viewModel.shouldRequestProfile {
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.profileFooterView.nameTextField.becomeFirstResponder()
            self.tableView.tableFooterView = self.profileFooterView
        } else {
            self.navigationItem.leftBarButtonItem?.isEnabled = true
            self.tableView.tableFooterView = self.messageListFooterView
        }

        self.sizeHeaderFooterViews()
    }

    private func sizeComposeTextView() {
        let textView = self.composeContainerView.composeView.textView
        let textSize = textView.sizeThatFits(CGSize(width: textView.bounds.inset(by: textView.textContainerInset).width, height: CGFloat.greatestFiniteMagnitude))

        self.composeContainerView.composeView.textViewHeightConstraint?.constant = textSize.height
    }

    private func sizeHeaderFooterViews() {
        let headerViewSize = self.headerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 100), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.headerView.bounds = CGRect(origin: .zero, size: headerViewSize)
        self.tableView.tableHeaderView = self.tableView.tableHeaderView

        if let footerView = self.tableView.tableFooterView {
            let footerSize = footerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 200), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
            footerView.bounds = CGRect(origin: .zero, size: footerSize)
            self.tableView.tableFooterView = footerView
        }
    }

    private func updateStackView(_ stackView: UIStackView, with message: MessageCenterViewModel.Message, at indexPath: IndexPath) {
        if stackView.arrangedSubviews.count < message.attachments.count {
            for _ in stackView.arrangedSubviews.count..<message.attachments.count {
                stackView.addArrangedSubview(AttachmentView(frame: .zero))
            }
        }

        for (index, subview) in stackView.arrangedSubviews.enumerated() {
            if index >= message.attachments.count {
                subview.isHidden = true
                continue
            }

            guard let attachmentIndicator = subview as? AttachmentView else {
                assertionFailure("Unknown subview in attachment stack view.")
                continue
            }

            subview.isHidden = false

            let attachment = message.attachments[index]
            attachmentIndicator.tag = index
            stackView.tag = self.tag(for: indexPath)

            if let thumbnail = attachment.thumbnail {
                attachmentIndicator.imageView.image = thumbnail
                attachmentIndicator.titleLabel.text = nil
            } else {
                attachmentIndicator.imageView.image = .apptentiveAttachmentPlaceholder
                attachmentIndicator.titleLabel.text = attachment.fileExtension
            }

            attachmentIndicator.accessibilityLabel = attachment.accessibilityLabel

            if let _ = attachment.localURL {
                attachmentIndicator.progressView.isHidden = true
                attachmentIndicator.gestureRecognizer.addTarget(self, action: #selector(showAttachment(_:)))
                attachmentIndicator.accessibilityHint = self.viewModel.showAttachmentButtonAccessibilityHint
            } else if attachment.downloadProgress == 0 {
                attachmentIndicator.progressView.isHidden = true
                attachmentIndicator.gestureRecognizer.addTarget(self, action: #selector(downloadAttachment(_:)))
                attachmentIndicator.accessibilityHint = self.viewModel.downloadAttachmentButtonAccessibilityHint
            } else {
                attachmentIndicator.progressView.isHidden = false
                attachmentIndicator.progressView.progress = attachment.downloadProgress
                attachmentIndicator.gestureRecognizer.removeTarget(self, action: nil)
                attachmentIndicator.accessibilityHint = nil
            }

            attachmentIndicator.imageView.adjustsImageSizeForAccessibilityContentSizeCategory = true
        }
    }

    private func showAttachmentOptions(sourceView: UIView) {
        let alertController = UIAlertController(title: "Select an attachment type.", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(
            UIAlertAction(
                title: "Images", style: .default,
                handler: { _ in
                    if #available(iOS 14, *) {
                        var config = PHPickerConfiguration()
                        config.selectionLimit = self.viewModel.remainingAttachmentSlots
                        config.filter = PHPickerFilter.images

                        let pickerViewController = PHPickerViewController(configuration: config)
                        pickerViewController.delegate = self
                        self.present(pickerViewController, animated: true, completion: nil)
                    } else {
                        let imagePickerController = UIImagePickerController()
                        imagePickerController.sourceType = .photoLibrary
                        imagePickerController.delegate = self
                        self.present(imagePickerController, animated: true, completion: nil)
                    }

                }))

        alertController.addAction(
            UIAlertAction(
                title: "Files", style: .default,
                handler: { _ in
                    if #available(iOS 14.0, *) {
                        let filePicker = UIDocumentPickerViewController(forOpeningContentTypes: self.viewModel.allUTTypes)
                        filePicker.delegate = self
                        self.present(filePicker, animated: true, completion: nil)
                    } else {
                        let filePicker = UIDocumentPickerViewController(documentTypes: self.viewModel.allFileTypes, in: .import)
                        filePicker.delegate = self
                        self.present(filePicker, animated: true, completion: nil)
                    }
                }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.view.accessibilityIdentifier = "AddAttachment"

        alertController.popoverPresentationController?.sourceView = sourceView

        self.present(alertController, animated: true, completion: nil)
    }

    private func indexPath(forTag tag: Int) -> IndexPath {
        return IndexPath(row: tag & 0xFFFF, section: tag >> 16)
    }

    private func tag(for indexPath: IndexPath) -> Int {
        return (indexPath.section << 16) | (indexPath.item & 0xFFFF)
    }

    private func updateDraftAttachments() {
        // Don't animate unless the count has changed (seems to avoid layout glitches).
        let visibleCount = self.composeContainerView.composeView.attachmentStackView.arrangedSubviews.filter { $0.isHidden == false }.count
        let shouldAnimate = visibleCount != self.viewModel.draftMessage.attachments.count

        let animations = {
            for (index, subview) in self.composeContainerView.composeView.attachmentStackView.arrangedSubviews.enumerated() {
                if index >= self.viewModel.draftAttachments.count {
                    subview.isHidden = true
                    continue
                }

                subview.isHidden = false

                guard let attachmentView = subview as? DraftAttachmentView else {
                    assertionFailure("Unknown subview in attachment stack view.")
                    continue
                }

                let attachment = self.viewModel.draftAttachments[index]

                attachmentView.imageView.accessibilityLabel = attachment.accessibilityLabel
                attachmentView.imageView.accessibilityHint = self.viewModel.showAttachmentButtonAccessibilityHint
                attachmentView.closeButton.accessibilityLabel = attachment.removeButtonAccessibilityLabel

                if let thumbnail = attachment.thumbnail {
                    attachmentView.imageView.image = thumbnail
                } else {
                    attachmentView.imageView.image = .apptentiveAttachmentPlaceholder
                }
            }
        }

        if shouldAnimate {
            UIView.animate(withDuration: 0.2, animations: animations)
        } else {
            animations()
        }
    }
}
