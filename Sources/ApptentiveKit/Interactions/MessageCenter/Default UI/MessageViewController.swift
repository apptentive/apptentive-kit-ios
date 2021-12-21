//
//  MessageViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageViewController: UITableViewController, UITextViewDelegate, MessageCenterViewModelDelegate {
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
        let sentByLocalUser = viewModel.sentByLocalUser(at: indexPath)

        if sentByLocalUser {
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageSentCellID, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageReceivedCellID, for: indexPath)
        }

        cell.selectionStyle = .none

        switch (sentByLocalUser, cell) {
        case (false, let receivedCell as MessageReceivedCell):
            receivedCell.messageLabel.text = self.viewModel.messageText(at: indexPath)
            receivedCell.dateLabel.text = self.viewModel.sentDateString(at: indexPath)
            receivedCell.senderLabel.text = self.viewModel.senderName(at: indexPath)
            receivedCell.profileImageView.url = self.viewModel.senderImageURL(at: indexPath)

        case (true, let sentCell as MessageSentCell):
            sentCell.messageLabel.text = self.viewModel.messageText(at: indexPath)
            sentCell.dateLabel.text = self.viewModel.sentDateString(at: indexPath)

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
        self.composeContainerView.composeView.sendButton.isEnabled = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - View Model Delegate

    func messageCenterViewModelMessageListDidUpdate(_: MessageCenterViewModel) {
        guard viewModel.numberOfMessageGroups > 0 else {
            return
        }
        DispatchQueue.main.async {
            UIView.transition(
                with: self.tableView,
                duration: 0.35,
                options: .curveEaseIn,
                animations: { self.tableView.reloadData() })
        }
        self.scrollToBottom(true)
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

    @objc func sendMessage() {
        self.viewModel.sendMessage(withBody: self.composeContainerView.composeView.textView.text)

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
}
