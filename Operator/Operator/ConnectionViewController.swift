//
//  ConnectionViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 3/13/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import UIKit
import ApptentiveKit

class ConnectionViewController: UITableViewController {

    @IBOutlet weak var conversationStateLabel: UILabel!
    @IBOutlet weak var conversationIDLabel: UILabel!
    @IBOutlet weak var conversationTokenLabel: UILabel!
    @IBOutlet weak var conversationSubjectLabel: UILabel!
    @IBOutlet weak var conversationExpiryLabel: UILabel!
    @IBOutlet weak var conversationActionButton: UIButton!
    @IBOutlet weak var refreshTokenButton: UIButton!

    @IBOutlet weak var connectionKeyLabel: UILabel!
    @IBOutlet weak var connectionSignatureLabel: UILabel!
    @IBOutlet weak var connectionURLLabel: UILabel!

    @IBOutlet weak var appReleaseVersionLabel: UILabel!
    @IBOutlet weak var appReleaseBuildLabel: UILabel!

    @IBOutlet weak var sdkDistributionLabel: UILabel!
    @IBOutlet weak var sdkVersionLabel: UILabel!

    var currentSubject: String?
    var currentState: Apptentive.ConversationState = .none
    let dateFormatter = DateFormatter()

    override func viewDidLoad() {
        self.refreshConnectionInfo()

        self.connectionKeyLabel.text = Bundle.main.object(forInfoDictionaryKey: "APPTENTIVE_API_KEY") as? String
        self.connectionSignatureLabel.text = Bundle.main.object(forInfoDictionaryKey: "APPTENTIVE_API_SIGNATURE") as? String
        self.connectionURLLabel.text = Bundle.main.object(forInfoDictionaryKey: "APPTENTIVE_API_BASE_URL") as? String

        self.appReleaseVersionLabel.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        self.appReleaseBuildLabel.text = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        self.sdkDistributionLabel.text = self.apptentive.distributionName
        self.sdkVersionLabel.text = self.apptentive.distributionVersion
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController, let jwtViewController = navigationController.viewControllers.first as? JWTViewController {
            if let currentSubject = self.currentSubject, self.currentState == .loggedIn {
                jwtViewController.mode = .refresh(subject: currentSubject)
            } else {
                jwtViewController.mode = .logIn
            }
        }
    }

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let configuration = UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc")) { action in
                if let cell = tableView.cellForRow(at: indexPath) {
                    UIPasteboard.general.string = cell.detailTextLabel?.text
                }
            }
            return UIMenu(title: "", children: [copyAction])
        }
        return configuration
    }

    func refreshConnectionInfo() {
        self.apptentive.getConnectionInfo { state, id, token in
            self.currentState = state

            self.conversationStateLabel.text = state.rawValue
            self.conversationIDLabel.text = id ?? "N/A"
            self.conversationTokenLabel.text = token ?? "N/A"

            if let token = token,
               let jwt = try? JWT(string: token) {
                self.conversationSubjectLabel.text = jwt.payload.subject
                self.currentSubject = jwt.payload.subject
                self.conversationExpiryLabel.text = jwt.payload.expiry.flatMap { self.dateFormatter.string(from: $0) } ?? "N/A"
            } else {
                self.conversationSubjectLabel.text = "N/A"
                self.conversationExpiryLabel.text = "N/A"
            }

            switch state {
            case .none, .placeholder, .anonymousPending, .legacyPending:
                self.conversationActionButton.setTitle("N/A", for: .normal)
                self.conversationActionButton.isEnabled = false
                self.refreshTokenButton.isEnabled = false
                break

            case .anonymous:
                self.conversationActionButton.setTitle("Log In", for: .normal)
                self.conversationActionButton.isEnabled = true
                self.refreshTokenButton.isEnabled = false
                break

            case .loggedIn:
                self.conversationActionButton.setTitle("Log Out", for: .normal)
                self.conversationActionButton.isEnabled = true
                self.refreshTokenButton.isEnabled = true
                break

            case .loggedOut:
                self.conversationActionButton.setTitle("Log In", for: .normal)
                self.conversationActionButton.isEnabled = true
                self.refreshTokenButton.isEnabled = false
                break
            }
        }
    }


    @IBAction func logInOrOut(_ sender: Any) {
        switch self.currentState {
        case .anonymous, .loggedOut:
            self.performSegue(withIdentifier: "PresentJWTBuilder", sender: self)

        case .loggedIn:
            self.apptentive.logOut() { (_: Result<Void, Error>) in }
            self.refreshConnectionInfo()
            self.currentSubject = nil

        default:
            break
        }
    }

    @IBAction func refreshToken(_ sender: Any) {
        self.performSegue(withIdentifier: "PresentJWTBuilder", sender: self)
    }

    @IBAction func returnToConnectionTab(_ sender: UIStoryboardSegue) {
        if sender.identifier == "CompleteLogin" {
            guard let jwtBuilder = sender.source as? JWTViewController else {
                print("Expected JWT View Controller as segue source")
                return
            }
            do {
                if self.currentState == .loggedIn {
                    try self.apptentive.updateToken(jwtBuilder.jwt) { result in
                        switch result{
                        case .success:
                            self.refreshConnectionInfo()

                        case .failure(let error):
                            let alertController = UIAlertController(title: "JWT Update Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(.init(title: "OK", style: .default))
                            self.present(alertController, animated: true)
                            self.refreshConnectionInfo()
                        }
                    }
                } else {
                    self.conversationActionButton.setTitle("Logging In…", for: .normal)
                    self.conversationActionButton.isEnabled = false

                    try self.apptentive.logIn(with: jwtBuilder.jwt) { result in
                        switch result {
                        case .success:
                            self.refreshConnectionInfo()

                        case .failure(let error):
                            let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(.init(title: "OK", style: .default))
                            self.present(alertController, animated: true)
                            self.refreshConnectionInfo()
                        }
                    }
                }
            } catch let error {
                let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(.init(title: "OK", style: .default))
                self.present(alertController, animated: true)
            }
        }
    }
}
