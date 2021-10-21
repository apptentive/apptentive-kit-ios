//
//  MessageViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/13/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessageViewController: UITableViewController {

    let viewModel: MessageCenterViewModel
    let messageReceivedCellID = "MessageCellReceived"
    let messageSentCellID = "MessageSentCell"

    init(viewModel: MessageCenterViewModel) {
        self.viewModel = viewModel
        super.init(style: .grouped)
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
        self.tableView.register(MessageReceivedCell.self, forCellReuseIdentifier: self.messageReceivedCellID)
        self.tableView.register(MessageSentCell.self, forCellReuseIdentifier: self.messageSentCellID)
    }

    //MARK: Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.viewModel.numberOfMessageGroups
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.numberOfMessagesInGroup(at: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        let isInbound = self.viewModel.isInbound(at: indexPath)

        if isInbound {
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageReceivedCellID, for: indexPath)
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: self.messageSentCellID, for: indexPath)
        }

        cell.selectionStyle = .none

        switch (isInbound, cell) {
        case (true, let receivedCell as MessageReceivedCell):
            receivedCell.messageLabel.text = self.viewModel.messageText(at: indexPath)
            receivedCell.dateLabel.text = self.viewModel.sentDateString(at: indexPath)
            receivedCell.senderLabel.text = self.viewModel.senderName(at: indexPath)
            receivedCell.profileImageView.url = self.viewModel.senderImageURL(at: indexPath)

        case (false, let sentCell as MessageSentCell):
            sentCell.messageLabel.text = self.viewModel.messageText(at: indexPath)
            sentCell.dateLabel.text = self.viewModel.sentDateString(at: indexPath)

        default:
            assertionFailure("Cell type doesn't match inbound value")
        }

        return cell
    }

    //MARK: - Targets

    @objc func closeMessageCenter() {
        self.viewModel.cancel()
        self.dismiss()
    }

    //MARK: - Private

    private func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
