//
//  SurveyFreeformShortCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 7/23/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveySingleLineCell: UITableViewCell {
    let textField: UITextField
    var tableViewStyle: UITableView.Style {
        didSet {
            switch self.tableViewStyle {
            case .insetGrouped:
                if #available(iOS 13.0, *) {
                    self.textField.borderStyle = .none
                    self.layer.borderColor = UIColor.tertiaryLabel.cgColor
                    self.layer.borderWidth = 1.0
                }
            default:
                self.textField.borderStyle = .roundedRect
                self.layer.borderColor = nil
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textField = UITextField(frame: .zero)
        self.tableViewStyle = .grouped

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.textField)
        self.configureTextField()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureTextField() {
        self.textField.borderStyle = .none

        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.adjustsFontForContentSizeCategory = true

        self.textField.font = .preferredFont(forTextStyle: .body)
        self.textField.returnKeyType = .done

        NSLayoutConstraint.activate([
            self.textField.topAnchor.constraint(equalToSystemSpacingBelow: self.contentView.topAnchor, multiplier: 1.0),
            self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textField.bottomAnchor, multiplier: 1.0),
            self.textField.leadingAnchor.constraint(equalToSystemSpacingAfter: self.contentView.leadingAnchor, multiplier: 1.0),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.textField.trailingAnchor, multiplier: 1.0),
        ])
    }
}
