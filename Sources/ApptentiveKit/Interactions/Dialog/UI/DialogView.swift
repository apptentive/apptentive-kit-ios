//
//  DialogView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 10/25/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Displays the contents of the dialog used for TextModal ("Note") and EnjoymentDialog ("Love Dialog") interactions.
public class DialogView: UIView {
    // MARK: - Appearance

    /// The foreground color of the title text.
    @objc public dynamic var titleTextColor: UIColor = .apptentiveLabel

    /// The foreground color of the message text in TextModal ("Note") interactions.
    @objc public dynamic var messageTextColor: UIColor = .apptentiveLabel

    /// The font used for the title text.
    @objc public dynamic var titleFont: UIFont = .preferredFont(forTextStyle: .headline)

    /// The font used for the message text in TextModal ("Note") interactions.
    @objc public dynamic var messageFont: UIFont = .preferredFont(forTextStyle: .footnote)

    /// An image placed along the top edge of the dialog.
    ///
    /// The image will be scaled to the width of the dialog, and the height will be determined by the aspect ratio of the image.
    @objc public dynamic var headerImage: UIImage?

    /// The radius of the corners of the dialog.
    @objc public dynamic var cornerRadius: CGFloat = 15

    /// The spacing between adjacent buttons.
    @objc public dynamic var buttonSpacing: CGFloat = 0

    /// The distance by which the group of buttons is inset from the edges of the dialog.
    @objc public dynamic var buttonInset: UIEdgeInsets = .zero

    /// Whether the separators between buttons are hidden.
    @objc public dynamic var separatorsAreHidden: Bool = false

    /// The color of the separators.
    @objc public dynamic var separatorColor: UIColor = .clear

    let blurEffect: UIBlurEffect
    let backgroundView: UIVisualEffectView
    let headerImageView: UIImageView
    let textScrollView: UIScrollView
    let textContentView: UIView
    let titleLabel: UILabel
    let messageLabel: UILabel
    let gradientView: GradientView
    let middleSeparator: UIVisualEffectView
    var buttonSeparators = [UIVisualEffectView]()
    let buttonStackView: UIStackView

    var headerImageViewHeightConstraint = NSLayoutConstraint()
    var buttonStackViewTopConstraint = NSLayoutConstraint()
    var buttonStackViewLeftConstraint = NSLayoutConstraint()
    var buttonStackViewRightConstraint = NSLayoutConstraint()
    var buttonStackViewBottomConstraint = NSLayoutConstraint()
    var titleBottomConstraint = NSLayoutConstraint()
    var messageBottomConstraint = NSLayoutConstraint()

    var isMessageLabelHidden = false {
        didSet {
            self.messageLabel.isHidden = self.isMessageLabelHidden
            self.titleBottomConstraint.isActive = self.isMessageLabelHidden
            self.messageBottomConstraint.isActive = !self.isMessageLabelHidden
        }
    }

    override init(frame: CGRect) {

        self.blurEffect = UIBlurEffect(style: .systemChromeMaterial)

        self.backgroundView = UIVisualEffectView(effect: self.blurEffect)
        self.headerImageView = UIImageView()
        self.textScrollView = UIScrollView()
        self.textContentView = UIView()
        self.titleLabel = UILabel()
        self.messageLabel = UILabel()
        self.gradientView = GradientView()
        self.middleSeparator = Self.buildSeparatorView(with: self.blurEffect)
        self.buttonStackView = UIStackView()

        super.init(frame: frame)

        self.configure()
        self.configureScrollView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swift-format-ignore
    public override func didMoveToWindow() {
        super.didMoveToWindow()

        self.titleLabel.textColor = self.titleTextColor
        self.titleLabel.font = self.titleFont

        self.messageLabel.textColor = self.messageTextColor
        self.messageLabel.font = self.messageFont

        if let headerImage = self.headerImage {
            self.headerImageView.image = headerImage
            self.headerImageView.isHidden = false

            NSLayoutConstraint.deactivate([self.headerImageViewHeightConstraint])
            NSLayoutConstraint.activate([
                self.headerImageView.heightAnchor.constraint(equalTo: self.headerImageView.widthAnchor, multiplier: headerImage.size.height / headerImage.size.width)
            ])
        }
    }

    // swift-format-ignore
    public override func layoutSubviews() {
        super.layoutSubviews()

        self.insetButtons()

        self.backgroundView.layoutIfNeeded()

        self.createButtonSeparatorsIfNeeded()

        self.layoutSeparators()

        self.gradientView.isHidden = self.textScrollView.contentSize.height <= self.textScrollView.bounds.height

        self.middleSeparator.isHidden = self.separatorsAreHidden
        self.middleSeparator.backgroundColor = self.separatorColor

        for separator in self.buttonSeparators {
            separator.isHidden = self.separatorsAreHidden
            separator.backgroundColor = self.separatorColor
        }

        self.layer.cornerRadius = self.cornerRadius
    }

    private func createButtonSeparatorsIfNeeded() {
        if self.buttonSeparators.count == 0 {
            for _ in 1..<self.buttonStackView.arrangedSubviews.count {
                let separatorView = Self.buildSeparatorView(with: self.blurEffect)

                self.buttonSeparators.append(separatorView)
                self.backgroundView.contentView.addSubview(separatorView)
            }
        }
    }

    private func layoutSeparators() {
        let separatorThickness = 1.0 / self.traitCollection.displayScale

        self.middleSeparator.frame = .init(x: 0, y: self.buttonStackView.frame.minY - separatorThickness - self.buttonInset.top, width: self.bounds.width, height: separatorThickness)

        for (index, separator) in self.buttonSeparators.enumerated() {
            switch self.buttonStackView.axis {
            case .horizontal:
                separator.autoresizingMask = .flexibleHeight
                let x = (self.buttonStackView.arrangedSubviews[index].frame.maxX + self.buttonStackView.arrangedSubviews[index + 1].frame.minX) / 2 + self.buttonStackView.frame.minX
                separator.frame = CGRect(x: x - separatorThickness / 2, y: self.buttonStackView.frame.minY - self.buttonInset.top, width: separatorThickness, height: self.buttonStackView.frame.height + self.buttonInset.top + self.buttonInset.bottom)

            case .vertical:
                separator.autoresizingMask = .flexibleWidth
                let y = (self.buttonStackView.arrangedSubviews[index].frame.maxY + self.buttonStackView.arrangedSubviews[index + 1].frame.minY) / 2 + self.buttonStackView.frame.minY
                separator.frame = CGRect(x: self.buttonStackView.frame.minX - self.buttonInset.left, y: y - separatorThickness / 2, width: self.buttonStackView.frame.width + self.buttonInset.left + self.buttonInset.right, height: separatorThickness)

            @unknown default:
                break
            }
        }
    }

    private func insetButtons() {
        self.buttonStackViewTopConstraint.constant = self.buttonInset.top
        self.buttonStackViewLeftConstraint.constant = self.buttonInset.left
        self.buttonStackViewRightConstraint.constant = self.buttonInset.right
        self.buttonStackViewBottomConstraint.constant = self.buttonInset.bottom

        self.buttonStackView.spacing = self.buttonSpacing
    }

    private func configure() {
        self.addSubview(self.backgroundView)
        self.backgroundView.contentView.addSubview(self.headerImageView)
        self.backgroundView.contentView.addSubview(self.textScrollView)
        self.backgroundView.contentView.addSubview(self.gradientView)
        self.backgroundView.contentView.addSubview(self.middleSeparator)
        self.backgroundView.contentView.addSubview(self.buttonStackView)

        // Cutting corners

        self.layer.cornerCurve = .continuous

        self.layer.masksToBounds = true

        self.headerImageView.contentMode = .scaleAspectFit

        self.buttonStackView.alignment = .center
        self.buttonStackView.distribution = .fillEqually

        self.setConstraints()
    }

    private func configureScrollView() {
        self.textScrollView.addSubview(self.textContentView)

        self.textContentView.addSubview(self.titleLabel)
        self.textContentView.addSubview(self.messageLabel)

        self.titleLabel.numberOfLines = 0
        self.titleLabel.textAlignment = .center
        self.titleLabel.lineBreakMode = .byWordWrapping
        self.titleLabel.adjustsFontForContentSizeCategory = true

        self.messageLabel.numberOfLines = 0
        self.messageLabel.textAlignment = .center
        self.messageLabel.lineBreakMode = .byWordWrapping
        self.messageLabel.adjustsFontForContentSizeCategory = true

        self.setScrollViewConstraints()
    }

    private func setConstraints() {
        self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.headerImageView.translatesAutoresizingMaskIntoConstraints = false
        self.textScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.gradientView.translatesAutoresizingMaskIntoConstraints = false
        self.buttonStackView.translatesAutoresizingMaskIntoConstraints = false

        self.headerImageViewHeightConstraint = self.headerImageView.heightAnchor.constraint(equalToConstant: 0)

        self.buttonStackViewTopConstraint = self.buttonStackView.topAnchor.constraint(equalTo: self.textScrollView.bottomAnchor)
        self.buttonStackViewLeftConstraint = self.buttonStackView.leftAnchor.constraint(equalTo: self.leftAnchor)
        self.buttonStackViewRightConstraint = self.rightAnchor.constraint(equalTo: self.buttonStackView.rightAnchor)
        self.buttonStackViewBottomConstraint = self.bottomAnchor.constraint(equalTo: self.buttonStackView.bottomAnchor)

        NSLayoutConstraint.activate([
            self.backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: self.backgroundView.bottomAnchor),

            self.headerImageView.topAnchor.constraint(equalTo: self.backgroundView.topAnchor),
            self.headerImageView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor),
            self.backgroundView.trailingAnchor.constraint(equalTo: self.headerImageView.trailingAnchor),
            self.headerImageViewHeightConstraint,

            self.textScrollView.topAnchor.constraint(equalTo: self.headerImageView.bottomAnchor),
            self.textScrollView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor),
            self.backgroundView.trailingAnchor.constraint(equalTo: self.textScrollView.trailingAnchor),

            self.gradientView.heightAnchor.constraint(equalToConstant: 2),
            self.gradientView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor),
            self.gradientView.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor),
            self.gradientView.bottomAnchor.constraint(equalTo: self.textScrollView.bottomAnchor, constant: -0.333),

            self.buttonStackViewTopConstraint,
            self.buttonStackViewLeftConstraint,
            self.buttonStackViewRightConstraint,
            self.buttonStackViewBottomConstraint,
        ])
    }

    private func setScrollViewConstraints() {
        self.textScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.textContentView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.messageLabel.translatesAutoresizingMaskIntoConstraints = false

        let textSpacingIdealConstraint = self.messageLabel.firstBaselineAnchor.constraint(equalTo: self.titleLabel.lastBaselineAnchor, constant: 20)
        textSpacingIdealConstraint.priority = UILayoutPriority(746)
        let textSpacingMinConstraint = self.messageLabel.firstBaselineAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.lastBaselineAnchor, constant: 17)
        let textSpacingMaxConstraint = self.messageLabel.firstBaselineAnchor.constraint(lessThanOrEqualTo: self.titleLabel.lastBaselineAnchor, constant: 20)

        let topSpacingIdealConstraint = self.titleLabel.firstBaselineAnchor.constraint(equalTo: self.textContentView.topAnchor, constant: 36)
        topSpacingIdealConstraint.priority = UILayoutPriority(748)
        let topSpacingMinConstraint = self.titleLabel.firstBaselineAnchor.constraint(greaterThanOrEqualTo: self.textContentView.topAnchor, constant: 22.3333)
        let topSpacingMaxConstraint = self.titleLabel.firstBaselineAnchor.constraint(lessThanOrEqualTo: self.textContentView.topAnchor, constant: 36)

        let heightExpanderConstraint = self.textScrollView.heightAnchor.constraint(equalTo: self.textContentView.heightAnchor)
        heightExpanderConstraint.priority = UILayoutPriority(749)

        self.titleBottomConstraint = self.textContentView.bottomAnchor.constraint(equalTo: self.titleLabel.lastBaselineAnchor, constant: 24)
        self.messageBottomConstraint = self.textContentView.bottomAnchor.constraint(equalTo: self.messageLabel.lastBaselineAnchor, constant: 24)

        NSLayoutConstraint.activate([
            self.textContentView.topAnchor.constraint(equalTo: self.textScrollView.topAnchor),
            self.textContentView.bottomAnchor.constraint(equalTo: self.textScrollView.bottomAnchor),
            heightExpanderConstraint,
            self.textContentView.widthAnchor.constraint(equalTo: self.textScrollView.widthAnchor),
            self.textContentView.rightAnchor.constraint(equalTo: self.textScrollView.rightAnchor),
            self.textContentView.leftAnchor.constraint(equalTo: self.textScrollView.leftAnchor),

            topSpacingIdealConstraint, topSpacingMinConstraint, topSpacingMaxConstraint,

            self.titleLabel.centerXAnchor.constraint(equalTo: self.textContentView.centerXAnchor),
            self.titleLabel.widthAnchor.constraint(equalTo: self.textContentView.widthAnchor, constant: -32),

            textSpacingIdealConstraint, textSpacingMinConstraint, textSpacingMaxConstraint,

            self.messageLabel.centerXAnchor.constraint(equalTo: self.textContentView.centerXAnchor),
            self.messageLabel.widthAnchor.constraint(equalTo: self.textContentView.widthAnchor, constant: -32),

            self.messageBottomConstraint,
        ])
    }

    private static func buildSeparatorView(with blurEffect: UIBlurEffect) -> UIVisualEffectView {
        let separatorView: UIVisualEffectView

        separatorView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect, style: .separator))

        separatorView.contentView.backgroundColor = .white

        return separatorView
    }

    class GradientView: UIView {
        override class var layerClass: AnyClass {
            return CAGradientLayer.self
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard let gradientLayer = self.layer as? CAGradientLayer else {
                apptentiveCriticalError("Expected CAGradientLayer as layer class")
                return
            }

            gradientLayer.colors = [UIColor(white: 0, alpha: 0).cgColor, UIColor(white: 0, alpha: 0.045).cgColor]
            gradientLayer.startPoint = .init(x: 0.5, y: 0)
            gradientLayer.endPoint = .init(x: 0.5, y: 1)
        }
    }
}
