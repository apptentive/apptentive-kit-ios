//
//  InteractionsViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 7/22/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import ApptentiveKit
import UIKit

class InteractionsViewController: UITableViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let manifestName = UserDefaults.standard.string(forKey: "OverrideManifest"),
           let interactionsDirectoryURL = Bundle.main.url(forResource: "Manifests", withExtension: "")
        {
            Task {
                try await self.apptentive.loadEngagementManifest(at: interactionsDirectoryURL.appendingPathComponent(manifestName).appendingPathExtension("json"))
                self.loadInteractions()
                self.updatePrompt()
            }
        } else {
            self.loadInteractions()
            self.updatePrompt()
        }
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.groupedInteractions.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groupedInteractions[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let interactionListItem = self.groupedInteractions[indexPath.section][indexPath.row]

        let cell = tableView.dequeueReusableCell(withIdentifier: "Interaction", for: indexPath)
        cell.textLabel?.text = interactionListItem.displayName
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return InteractionType(rawValue: interactionGroupNames[section])?.displayName ?? "Unknown"
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Task {
            let _ = try await self.apptentive.presentInteraction(with: self.groupedInteractions[indexPath.section][indexPath.row].id)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - Actions

    @IBAction func reload(_ sender: UIBarButtonItem) {
        self.loadInteractions()
    }

    @IBAction func doneChoosingManifest(sender: UIStoryboardSegue) {
        self.loadInteractions()

        self.navigationController?.isNavigationBarHidden = true
        self.updatePrompt()
        self.navigationController?.isNavigationBarHidden = false
    }

    // MARK: - Private

    private var interactionGroupNames = [String]()
    private var groupedInteractions = [[Apptentive.InteractionListItem]]()

    private func loadInteractions() {
        Task {
            let interactions = await self.apptentive.getInteractionList()
            let interactionGroups = Dictionary(grouping: interactions) { $0.typeName }

            self.interactionGroupNames = Array(interactionGroups.keys).sorted()
            self.groupedInteractions = self.interactionGroupNames.compactMap { interactionGroups[$0] }

            self.tableView.reloadData()
        }
    }

    private func updatePrompt() {
        if let manifestOverride = self.apptentive.engagementManifestURL?.lastPathComponent {
            self.navigationItem.prompt = "Using “\(manifestOverride)” Manifest"
        } else {
            self.navigationItem.prompt = nil
        }
    }

    private enum InteractionType: String {
        case AppleRatingDialog
        case AppStoreRating
        case TextModal
        case NotImplemented
        case MessageCenter
        case EnjoymentDialog
        case Survey
        case NavigateToLink

        var displayName: String {
            switch self {
            case .AppleRatingDialog:
                return "Apple Rating Dialog"

            case .AppStoreRating:
                return "Legacy Rating Dialog"

            case .TextModal:
                return "Note"

            case .EnjoymentDialog:
                return "Love Dialog"

            case .MessageCenter:
                return "Message Center"

            case .NavigateToLink:
                return "Open URL"

            default:
                return self.rawValue
            }
        }
    }
}
