//
//  ConnectionViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 3/13/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import UIKit
import SwiftJWT

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

    var buttonMode: ButtonMode = .notAvailable
    var currentSubject: String?
    let dateFormatter = DateFormatter()

    enum ButtonMode {
        case logIn
        case logOut
        case notAvailable
    }

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
            if let subject = self.currentSubject {
                jwtViewController.mode = .refresh(subject: subject)
            } else {
                jwtViewController.mode = .logIn
            }
        }
    }


    func refreshConnectionInfo() {
        self.apptentive.getConnectionInfo { state, id, token, _, buttonLabel in
            self.conversationStateLabel.text = state ?? "N/A"
            self.conversationIDLabel.text = id ?? "N/A"
            self.conversationTokenLabel.text = token ?? "N/A"

            if let token = token,
               let secretString = Bundle.main.object(forInfoDictionaryKey: "APPTENTIVE_JWT_SECRET") as? String,
               let secret = secretString.data(using: .utf8),
               let jwt = try? JWT<JWTViewController.JWTClaims>(jwtString: token, verifier: .hs512(key: secret)) {
                self.conversationSubjectLabel.text = jwt.claims.sub
                self.currentSubject = jwt.claims.sub
                self.conversationExpiryLabel.text = jwt.claims.exp.flatMap { self.dateFormatter.string(from: $0) } ?? "N/A"
            } else {
                self.conversationSubjectLabel.text = "N/A"
                self.conversationExpiryLabel.text = "N/A"
            }

            if let buttonLabel = buttonLabel {
                self.conversationActionButton.setTitle(buttonLabel, for: .normal)
                self.conversationActionButton.isEnabled = true

                if buttonLabel == "Log In" {
                    self.buttonMode = .logIn
                } else if buttonLabel == "Log Out" {
                    self.buttonMode = .logOut
                } else {
                    self.buttonMode = .notAvailable
                }

                self.refreshTokenButton.isEnabled = self.currentSubject != nil
            } else {
                self.conversationActionButton.setTitle("N/A", for: .normal)
                self.conversationActionButton.isEnabled = false
                self.buttonMode = .notAvailable
                self.refreshTokenButton.isEnabled = false
            }
        }
    }


    @IBAction func logInOrOut(_ sender: Any) {
        switch self.buttonMode {
        case .logIn:
            self.performSegue(withIdentifier: "PresentJWTBuilder", sender: self)

        case .logOut:
            self.apptentive.logOut()
            self.refreshConnectionInfo()
            self.currentSubject = nil

        case .notAvailable:
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
                if self.currentSubject != nil {
                    try self.apptentive.updateToken(jwtBuilder.jwt) { result in
                        switch result{
                        case .success:
                            self.refreshConnectionInfo()

                        case .failure(let error):
                            let alertController = UIAlertController(title: "JWT Update Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(.init(title: "OK", style: .default))
                            self.present(alertController, animated: true)
                        }
                    }
                } else {
                    try self.apptentive.logIn(with: jwtBuilder.jwt) { result in
                        switch result {
                        case .success:
                            self.refreshConnectionInfo()

                        case .failure(let error):
                            let alertController = UIAlertController(title: "Login Error", message: error.localizedDescription, preferredStyle: .alert)
                            alertController.addAction(.init(title: "OK", style: .default))
                            self.present(alertController, animated: true)
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
