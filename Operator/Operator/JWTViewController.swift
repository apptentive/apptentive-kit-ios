//
//  JWTViewController.swift
//  Operator
//
//  Created by Frank Schmitt on 3/14/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import UIKit
import SwiftJWT

class JWTViewController: UITableViewController {
    @IBOutlet weak var expiryDatePicker: UIDatePicker!
    @IBOutlet weak var loginButtonItem: UIBarButtonItem!
    @IBOutlet weak var secretStatusLabel: UILabel!

    enum Mode {
        case logIn
        case refresh(subject: String)
    }

    var jwt: String {
        get throws {
            // It seems weird that we would use the UTF-8 value of the string version of the secret as the key, but whatevs.
            guard let subject = self.jwtSubject, let secretString = self.signingSecret, let secret = secretString.data(using: .utf8) else {
                throw JWTBuilderError.badSecretOrSub
            }

            var myJWT = JWT(header: .init(), claims: JWTClaims(sub: subject, exp: self.expiryDatePicker.date))
            let signer = JWTSigner.hs512(key: secret)

            return try myJWT.sign(using: signer)
        }
    }

    var mode: Mode = .logIn {
        didSet {
            switch self.mode {
            case .logIn:
                self.loginButtonItem.title = "Log In"

            case .refresh(subject: let subject):
                self.loginButtonItem.title = "Refresh"
                self.jwtSubject = subject
            }
        }
    }

    struct JWTClaims: Claims {
        let sub: String
        let exp: Date
        let iat: Date
        let iss: String

        init(sub: String, exp: Date) {
            self.sub = sub
            self.exp = exp
            self.iat = Date()
            self.iss = "ClientTeam"
        }
    }

    private let jwtSubjects = ["Alex", "Barbara", "Charlie"]

    private var jwtSubject: String? {
        get {
            return self.subjectIndex.flatMap { self.jwtSubjects[$0] }
        }
        set {
            self.subjectIndex = newValue.flatMap { jwtSubjects.firstIndex(of: $0) }
        }
    }

    private var signingSecret: String?

    var subjectIndex: Int?

    override func viewDidLoad() {
        self.expiryDatePicker.date = Date(timeIntervalSinceNow: 3 * 24 * 60 * 60)

        self.signingSecret = Bundle.main.object(forInfoDictionaryKey: "APPTENTIVE_JWT_SECRET") as? String

        if let signingSecret = self.signingSecret {
            self.secretStatusLabel.text = signingSecret.prefix(4) + "…" + signingSecret.suffix(4)
        }

    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if case .refresh = self.mode {
            self.loginButtonItem.isEnabled = true

            if let subjectIndex = self.subjectIndex {
                self.tableView.cellForRow(at: .init(row: subjectIndex, section: 0))?.accessoryType = .checkmark
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if case .logIn = self.mode, indexPath.section == 0 {

            if let previousSubjectIndex = self.subjectIndex, let previousCell = tableView.cellForRow(at: [0, previousSubjectIndex]) {
                previousCell.accessoryType = .none
            }

            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
            self.subjectIndex = indexPath.row
        }

        tableView.deselectRow(at: indexPath, animated: true)
        self.loginButtonItem.isEnabled = self.subjectIndex != nil && self.signingSecret != nil
    }
}

enum JWTBuilderError: Swift.Error {
    case badSecretOrSub
}

extension Data {
    init?(hexString: String) {
        // TODO: Use `Scanner` when we drop iOS <13 support.
        var result = Data()
        var index = hexString.startIndex

        while index < hexString.endIndex {
            guard let endIndex = hexString.index(index, offsetBy: 2, limitedBy: hexString.endIndex) else {
                return nil
            }

            guard let byte = UInt8(String(hexString[index..<endIndex]), radix: 16) else {
                return nil
            }

            result.append(byte)

            index = endIndex
        }

        self = result
    }
}

