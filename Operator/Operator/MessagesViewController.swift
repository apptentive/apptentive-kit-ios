//
//  MessagesViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 9/22/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class MessagesViewController: UITableViewController {
    @IBAction func cancelAttachmentText(sender: UIStoryboardSegue) {
        // do nothing, just dismiss.
    }

    @IBAction func sendAttachmentText(sender: UIStoryboardSegue) {
        guard let textViewController = sender.source as? TextViewController else {
            return assertionFailure("Expecting TextViewController")
        }

        self.apptentive.sendAttachment(textViewController.textField.text ?? "")
    }
}
