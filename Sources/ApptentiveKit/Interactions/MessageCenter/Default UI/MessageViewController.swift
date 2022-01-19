//
//  MessageViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import PhotosUI
import UIKit

class MessageViewController: UITableViewController, UITextViewDelegate, MessageCenterViewModelDelegate, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate, UIDocumentPickerDelegate {

    let viewModel: MessageCenterViewModel
    let headerView: GreetingHeaderView
    let footerView: MessageListFooterView
    let composeContainerView: MessageCenterComposeContainerView
    let messageReceivedCellID = "MessageCellReceived"
    let messageSentCellID = "MessageSentCell"

    private var shouldScrollToBottom = true

    init(viewModel: MessageCenterViewModel) {
        self.composeContainerView = MessageCenterComposeContainerView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 88)))
        self.headerView = GreetingHeaderView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 320)))
        self.footerView = MessageListFooterView(frame: CGRect(origin: .zero, size: CGSize(width: 320, height: 88)))

        self.viewModel = viewModel
        super.init(style: .grouped)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = .apptentiveClose
        self.navigationItem.rightBarButtonItem?.target = self
        self.navigationItem.rightBarButtonItem?.action = #selector(closeMessageCenter)
        self.navigationItem.title = self.viewModel.headingTitle

        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 500
        self.tableView.keyboardDismissMode = .interactive
        self.tableView.register(MessageReceivedCell.self, forCellReuseIdentifier: self.messageReceivedCellID)
        self.tableView.register(MessageSentCell.self, forCellReuseIdentifier: self.messageSentCellID)

        self.composeContainerView.composeView.textView.delegate = self
        self.composeContainerView.composeView.placeholderLabel.text = self.viewModel.composerPlaceholderText
        self.composeContainerView.composeView.sendButton.setTitle(self.viewModel.composerSendButtonTitle, for: .normal)
        self.composeContainerView.composeView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        self.composeContainerView.composeView.sendButton.isEnabled = self.viewModel.canSendMessage
        self.composeContainerView.composeView.sendButton.accessibilityLabel = self.viewModel.composerSendButtonTitle

        self.composeContainerView.composeView.attachmentButton.addTarget(self, action: #selector(addAttachment), for: .touchUpInside)
        self.composeContainerView.composeView.attachmentButton.isEnabled = self.viewModel.canAddAttachment
        self.composeContainerView.composeView.sendButton.accessibilityLabel = self.viewModel.composerAttachButtonTitle

        self.textViewDidChange(self.composeContainerView.composeView.textView)

        self.tableView.tableHeaderView = self.headerView
        self.headerView.greetingTitleLabel.text = self.viewModel.greetingTitle
        self.headerView.greetingBodyLabel.text = self.viewModel.greetingBody

        self.tableView.tableFooterView = self.footerView
        self.footerView.statusTextLabel.text = self.viewModel.statusBody

        self.viewModel.delegate = self
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.shouldScrollToBottom {
            self.scrollToBottom(false)
            self.shouldScrollToBottom = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.sizeHeaderFooterViews()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        self.sizeHeaderFooterViews()
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var inputAccessoryView: UIView? {
        return self.composeContainerView
    }

    // MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfMessageGroups
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfMessagesInGroup(at: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        let message = self.viewModel.message(at: indexPath)

        if message.messageState == .outbound {
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageSentCellID, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageReceivedCellID, for: indexPath)
        }

        cell.selectionStyle = .none

        switch (message.messageState, cell) {
        case (.inbound, let receivedCell as MessageReceivedCell):
            receivedCell.messageLabel.text = message.body
            receivedCell.dateLabel.text = message.sentDateString
            receivedCell.senderLabel.text = message.senderName
            receivedCell.profileImageView.url = message.senderImageURL

        case (.outbound, let sentCell as MessageSentCell):
            sentCell.messageLabel.text = message.body
            sentCell.dateLabel.text = message.sentDateString

        default:
            assertionFailure("Cell type doesn't match inbound value")
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.viewModel.dateStringForMessagesInGroup(at: section)
    }

    // MARK: - Text View Delegate

    func textViewDidChange(_ textView: UITextView) {
        let textSize = textView.sizeThatFits(CGSize(width: textView.bounds.inset(by: textView.textContainerInset).width, height: CGFloat.greatestFiniteMagnitude))

        self.composeContainerView.composeView.textViewHeightConstraint?.constant = textSize.height

        self.viewModel.messageBody = textView.text
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true, completion: nil)
        let info = MessageViewController.convertFromUIImagePickerControllerInfoKeyDictionary(info)
        if let image = info[MessageViewController.convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            do {
                try self.viewModel.addImageAttachment(image)
            } catch let error {
                ApptentiveLogger.default.error("Error adding attachment: \(error)")
            }
        } else {
            ApptentiveLogger.default.debug("Unable to find picked image!")
        }

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
                    ApptentiveLogger.default.error("Expected UIImage from PHPickerViewController.")
                    return
                }

                do {
                    try self.viewModel.addImageAttachment(image)
                } catch let error {
                    ApptentiveLogger.default.error("Error adding attachment: \(error)")
                }
            }
        }
    }

    // MARK: - UIDocumentPickerDelegate

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        controller.dismiss(animated: true)
        do {
            try self.viewModel.addFileAttachment(at: url)
        } catch let error {
            ApptentiveLogger.default.error("Error adding attachment: \(error)")
        }
    }

    // MARK: - View Model Delegate

    func messageCenterViewModelMessageListDidUpdate(_ viewModel: MessageCenterViewModel) {
        guard viewModel.numberOfMessageGroups > 0 else {
            return
        }

        self.tableView.reloadData()
        self.scrollToBottom(true)
    }

    func messageCenterViewModelCanAddAttachmentDidUpdate(_ viewModel: MessageCenterViewModel) {
        self.composeContainerView.composeView.attachmentButton.isEnabled = viewModel.canAddAttachment
    }

    func messageCenterViewModelCanSendMessageDidUpdate(_ viewModel: MessageCenterViewModel) {
        self.composeContainerView.composeView.sendButton.isEnabled = viewModel.canSendMessage
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

    @objc func closeMessageCenter() {
        self.viewModel.cancel()
        self.dismiss()
    }

    @objc func addAttachment() {
        self.showAttachmentOptions()
    }

    @objc func sendMessage() {
        do {
            try self.viewModel.sendMessage()
        } catch let error {
            ApptentiveLogger.default.error("Error when trying to send message: \(error).")
        }

        self.composeContainerView.composeView.textView.text = ""
        self.composeContainerView.composeView.textView.resignFirstResponder()

        self.textViewDidChange(self.composeContainerView.composeView.textView)
        self.composeContainerView.composeView.textViewDidChange()
    }

    // MARK: - Private

    private func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    private func scrollToBottom(_ animated: Bool) {
        DispatchQueue.main.async {
            let lastSectionIndex = self.tableView.numberOfSections - 1
            guard lastSectionIndex >= 0 && self.tableView.numberOfRows(inSection: lastSectionIndex) > 0 else {
                return
            }

            let lastIndexPath = IndexPath(row: self.tableView.numberOfRows(inSection: lastSectionIndex) - 1, section: lastSectionIndex)

            self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: animated)
        }
    }

    private func sizeHeaderFooterViews() {
        let headerViewSize = self.headerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 100), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.headerView.bounds = CGRect(origin: .zero, size: headerViewSize)

        let footerViewSize = self.footerView.systemLayoutSizeFitting(CGSize(width: self.tableView.bounds.width, height: 100), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        self.footerView.bounds = CGRect(origin: .zero, size: footerViewSize)
    }

    private func showAttachmentOptions() {
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
                        let filePicker = UIDocumentPickerViewController(forOpeningContentTypes: UIDocumentPickerViewController.allUTTypes)
                        filePicker.delegate = self
                        self.present(filePicker, animated: true, completion: nil)
                    } else {
                        let filePicker = UIDocumentPickerViewController(documentTypes: UIDocumentPickerViewController.allFileTypes, in: .import)
                        filePicker.delegate = self
                        self.present(filePicker, animated: true, completion: nil)
                    }
                }))

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.view.accessibilityIdentifier = "AddAttachment"
        self.present(alertController, animated: true, completion: nil)
    }

    private static func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) })
    }

    private static func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }
}
