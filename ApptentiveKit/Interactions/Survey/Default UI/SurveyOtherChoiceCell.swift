//
//  SurveyOtherChoiceCell.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 12/16/20.
//  Copyright © 2020 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyOtherChoiceCell: UITableViewCell {
    let textField: UITextField

    var isMarkedAsInvalid: Bool {
        didSet {
            if self.isMarkedAsInvalid {
                self.textField.layer.borderColor = UIColor.apptentiveError.cgColor
            } else {
                self.textField.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.textField = UITextField(frame: .zero)

        self.isMarkedAsInvalid = false

        super.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.textLabel?.numberOfLines = 0
        self.textLabel?.lineBreakMode = .byWordWrapping

        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.textField)
        self.configureTextField()
    }

    func setMarkedAsInvalid(_ markedAsInvalid: Bool, animated: Bool) {
        let animationDuration = animated ? 0.25 : 0

        UIView.animate(withDuration: animationDuration) {
            self.isMarkedAsInvalid = markedAsInvalid
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        self.imageView?.isHighlighted = selected
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        self.imageView?.isHighlighted = highlighted || self.isSelected
    }

    private func configureTextField() {
        self.textField.borderStyle = .roundedRect

        // Set up additional border to display validation state
        self.textField.layer.borderWidth = 1.0 / self.traitCollection.displayScale
        self.textField.layer.borderColor = UIColor.clear.cgColor
        self.textField.layer.cornerRadius = 6.0

        self.textField.translatesAutoresizingMaskIntoConstraints = false
        self.textField.adjustsFontForContentSizeCategory = true
        let sizeCategory = UIApplication.shared.preferredContentSizeCategory

        //Very large text (accessibility) is causing the placeholder label to overlap the image button. This helps keep the placeholder in place as the size scales.
        if sizeCategory >= .accessibilityMedium {
            let spacerView = UIView(frame: CGRect(x: 0, y: 0, width: 75, height: self.frame.size.height))
            self.textField.leftView = spacerView
            self.textField.leftViewMode = .always
        }

        self.textField.font = .preferredFont(forTextStyle: .body)
        self.textField.returnKeyType = .done

        guard let textLabel = self.textLabel else {
            return
        }

        NSLayoutConstraint.activate([
            self.textField.topAnchor.constraint(equalToSystemSpacingBelow: self.contentView.topAnchor, multiplier: 1.0),
            self.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.textField.bottomAnchor, multiplier: 1.0),
            self.textField.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor, constant: -7.0),
            self.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.textField.trailingAnchor, multiplier: 1.0),
        ])
    }
}
