//
//  DialogButton.swift
//  AlertController
//
//  Created by Frank Schmitt on 8/6/25.
//

import UIKit

@available(iOS 26, *)
public class GlassDialogButton: UIView {
    private let label: UILabel

    var text: String? {
        didSet {
            self.label.text = text
            self.accessibilityLabel = text
        }
    }

    var completion: (() -> Void)?

    private var dynamicTypeObservation: UITraitChangeRegistration?
    private let fontMetrics: UIFontMetrics
    private var heightConstraint = NSLayoutConstraint()

    override init(frame: CGRect) {
        self.label = UILabel()
        self.fontMetrics = UIFontMetrics(forTextStyle: .body)

        super.init(frame: frame)

        self.addSubview(self.label)

        self.dynamicTypeObservation = registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.handleDynamicTypeChange()
        }

        self.configure()
    }

    @MainActor
    deinit {
        self.dynamicTypeObservation.flatMap { unregisterForTraitChanges($0) }
    }

    private func handleDynamicTypeChange() {
        self.heightConstraint.constant = self.fontMetrics.scaledValue(for: 48, compatibleWith: self.traitCollection)
    }

    private func configure() {
        self.backgroundColor = .apptentiveDialogButtonBackground

        self.cornerConfiguration = .apptentiveDialogButton
        self.layer.borderColor = UIColor.apptentiveButtonBorder.cgColor
        self.layer.borderWidth = .apptentiveButtonBorderWidth

        self.label.translatesAutoresizingMaskIntoConstraints = false
        self.label.font = .apptentiveDialogButton
        self.label.textColor = .apptentiveDialogButtonLabel
        self.label.adjustsFontForContentSizeCategory = true
        self.label.adjustsFontSizeToFitWidth = true

        self.heightConstraint = self.heightAnchor.constraint(equalToConstant: 48)

        NSLayoutConstraint.activate([
            self.label.topAnchor.constraint(equalTo: self.topAnchor),
            self.label.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            self.label.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            self.label.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, constant: -60),

            self.heightConstraint,
        ])

        self.isAccessibilityElement = true
        self.accessibilityLabel = label.text
        self.accessibilityTraits = [.button]

        self.handleDynamicTypeChange()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
