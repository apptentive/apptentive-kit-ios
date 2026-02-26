//
//  DialogView.swift
//  AlertController
//
//  Created by Frank Schmitt on 8/1/25.
//

import UIKit

@available(iOS 26, *)
class GlassDialogView: UIView {
    /// The distance by which the group of buttons is inset from the edges of the dialog.
    @objc public dynamic var buttonInset: UIEdgeInsets = .zero

    internal let titleLabel: RichTextLabel
    internal let messageLabel: RichTextLabel
    internal let altTextLabel: UILabel
    internal let imageView: UIImageView
    internal let buttonStackView: UIStackView
    internal let gradientView: GradientView
    internal let contentScrollView: UIScrollView
    internal let gestureRecognizer: UILongPressGestureRecognizer

    private let contentView: UIView
    private let backgroundView: UIVisualEffectView
    private let buttonScrollView: UIScrollView
    private let visualEffect: UIGlassEffect

    private var dynamicTypeObservation: UITraitChangeRegistration?
    private let headingFontMetrics: UIFontMetrics
    private let subheadFontMetrics: UIFontMetrics
    private let bodyFontMetrics: UIFontMetrics

    internal var imageTopConstraint = NSLayoutConstraint()
    internal var imageLeadingConstraint = NSLayoutConstraint()
    internal var imageTrailingConstraint = NSLayoutConstraint()
    internal var altTextBottomConstraint = NSLayoutConstraint()
    internal var titleRequiredTopConstraint = NSLayoutConstraint()
    internal var titlePreferredTopConstraint = NSLayoutConstraint()
    internal var titleRequiredBottomConstraint = NSLayoutConstraint()
    internal var titleMessageSpaceMinimumConstraint = NSLayoutConstraint()
    internal var titleMessageSpaceMaximumConstraint = NSLayoutConstraint()
    internal var titleMessageSpacePreferredConstraint = NSLayoutConstraint()
    internal var messagePreferredTopConstraint = NSLayoutConstraint()
    internal var messageRequiredBottomConstraint = NSLayoutConstraint()
    internal var contentViewCollapseConstraint = NSLayoutConstraint()
    internal var divvierUpperConstraint = NSLayoutConstraint()
    internal var headerImageAspectConstraint = NSLayoutConstraint()
    internal var buttonHeightRequiredConstraint = NSLayoutConstraint()
    internal var buttonHeightPreferredConstraint = NSLayoutConstraint()

    override init(frame: CGRect) {
        self.titleLabel = RichTextLabel()
        self.messageLabel = RichTextLabel()
        self.altTextLabel = UILabel()
        self.imageView = UIImageView()
        self.contentView = UIView()

        self.buttonStackView = UIStackView()

        self.visualEffect = UIGlassEffect()
        self.backgroundView = UIVisualEffectView(effect: self.visualEffect)
        self.gradientView = GradientView()

        self.contentScrollView = UIScrollView()
        self.buttonScrollView = UIScrollView()

        self.gestureRecognizer = UILongPressGestureRecognizer()

        self.headingFontMetrics = UIFontMetrics(forTextStyle: .headline)
        self.subheadFontMetrics = UIFontMetrics(forTextStyle: .subheadline)
        self.bodyFontMetrics = UIFontMetrics(forTextStyle: .body)

        super.init(frame: frame)

        self.dynamicTypeObservation = registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (self: Self, previousTraitCollection: UITraitCollection) in
            self.handleDynamicTypeChange()
        }

        self.configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @MainActor deinit {
        self.dynamicTypeObservation.flatMap { unregisterForTraitChanges($0) }
    }

    private func configure() {
        self.buttonStackView.addGestureRecognizer(self.gestureRecognizer)
        self.gestureRecognizer.minimumPressDuration = 0
        self.gestureRecognizer.addTarget(self, action: #selector(didTap))
        self.gestureRecognizer.allowableMovement = 10

        self.clipsToBounds = true
        self.layer.cornerRadius = CGFloat.apptentiveDialogCornerRadius
        self.layer.cornerCurve = .continuous

        if let backgroundColorOverride = UIColor.apptentiveDialogBackground {
            self.backgroundView.contentView.backgroundColor = backgroundColorOverride
        }

        self.backgroundView.cornerConfiguration = .corners(radius: .fixed(CGFloat.apptentiveDialogCornerRadius))

        self.addSubview(backgroundView)

        self.backgroundView.contentView.addSubview(self.contentScrollView)
        self.backgroundView.contentView.addSubview(self.buttonScrollView)
        self.backgroundView.contentView.addSubview(self.gradientView)

        self.contentScrollView.addSubview(self.contentView)

        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.altTextLabel)
        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.messageLabel)

        self.buttonScrollView.addSubview(self.buttonStackView)

        self.contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.buttonScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.translatesAutoresizingMaskIntoConstraints = false

        self.imageView.translatesAutoresizingMaskIntoConstraints = false

        self.altTextLabel.translatesAutoresizingMaskIntoConstraints = false
        self.altTextLabel.font = .preferredFont(forTextStyle: .footnote)
        self.altTextLabel.adjustsFontForContentSizeCategory = true
        self.altTextLabel.numberOfLines = 0
        self.altTextLabel.textAlignment = .center

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.font = .preferredFont(forTextStyle: .headline)
        self.titleLabel.adjustsFontForContentSizeCategory = true
        self.titleLabel.numberOfLines = 0
        self.titleLabel.accessibilityIdentifier = "DialogTitleText"
        self.titleLabel.font = .apptentiveDialogTitle
        self.titleLabel.textColor = .apptentiveDialogTitle

        self.messageLabel.translatesAutoresizingMaskIntoConstraints = false
        self.messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        self.messageLabel.adjustsFontForContentSizeCategory = true
        self.messageLabel.numberOfLines = 0
        self.messageLabel.accessibilityIdentifier = "DialogMessageText"
        self.messageLabel.font = .apptentiveDialogMessage
        self.messageLabel.textColor = .apptentiveDialogMessage

        self.backgroundView.translatesAutoresizingMaskIntoConstraints = false
        self.gradientView.translatesAutoresizingMaskIntoConstraints = false

        self.contentScrollView.translatesAutoresizingMaskIntoConstraints = false
        self.buttonScrollView.translatesAutoresizingMaskIntoConstraints = false

        self.buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        self.buttonStackView.spacing = .apptentiveDialogButtonSpacing
        self.buttonStackView.axis = .vertical
        self.buttonStackView.alignment = .fill
        self.buttonStackView.distribution = .fill
        self.buttonStackView.spacing = .apptentiveDialogButtonSpacing

        if let headerImage = UIImage.apptentiveDialogHeader {
            self.imageView.image = headerImage
            self.imageView.isHidden = false

            guard headerImage.size.width > 0 else {
                return
            }

            self.setImageAspectRatio(headerImage.size.height / headerImage.size.width)
        }

        self.configureConstraints()
    }

    @objc func didTap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: self.buttonStackView)
        let hitView = self.buttonStackView.hitTest(tapLocation, with: nil)

        switch sender.state {

        case .began:
            if let _ = hitView as? GlassDialogButton {
                self.setScale(1.01, animated: true)
            }

        case .ended:
            if let action = hitView as? GlassDialogButton {
                action.completion?()
            }
            self.setScale(1.01, animated: true)

        case .cancelled, .failed:
            self.setScale(1, animated: true)

        default:
            break
        }
    }

    func setScale(_ scale: CGFloat, animated: Bool) {
        let scaleClosure = {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.allowUserInteraction, .beginFromCurrentState]
            ) {
                scaleClosure()
            }
        } else {
            scaleClosure()
        }
    }

    func setImageAspectRatio(_ ratio: CGFloat) {
        self.headerImageAspectConstraint.isActive = false

        self.headerImageAspectConstraint = self.imageView.heightAnchor.constraint(equalTo: self.imageView.widthAnchor, multiplier: ratio, constant: 0)
        self.headerImageAspectConstraint.priority = .defaultHigh

        self.headerImageAspectConstraint.isActive = true
    }

    private func configureConstraints() {
        self.imageTopConstraint = self.imageView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 0)
        self.imageLeadingConstraint = self.imageView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 0)
        self.imageTrailingConstraint = self.contentView.trailingAnchor.constraint(equalTo: self.imageView.trailingAnchor, constant: 0)

        self.altTextBottomConstraint = self.imageView.bottomAnchor.constraint(equalToSystemSpacingBelow: self.altTextLabel.bottomAnchor, multiplier: 1)

        self.titlePreferredTopConstraint = self.titleLabel.firstBaselineAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 38.3871)
        self.titlePreferredTopConstraint.priority = UILayoutPriority(746)
        self.titleRequiredTopConstraint = self.titleLabel.firstBaselineAnchor.constraint(greaterThanOrEqualTo: self.imageView.bottomAnchor, constant: 38.3871)

        self.titleMessageSpacePreferredConstraint = self.messageLabel.firstBaselineAnchor.constraint(equalTo: self.titleLabel.lastBaselineAnchor, constant: 25.9004)
        self.titleMessageSpacePreferredConstraint.priority = UILayoutPriority(746)

        self.titleMessageSpaceMinimumConstraint = self.messageLabel.firstBaselineAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.lastBaselineAnchor, constant: 18.6677)
        self.titleMessageSpaceMaximumConstraint = self.messageLabel.firstBaselineAnchor.constraint(lessThanOrEqualTo: self.titleLabel.lastBaselineAnchor, constant: 25.9004)

        self.titleRequiredBottomConstraint = self.contentView.bottomAnchor.constraint(greaterThanOrEqualTo: self.titleLabel.lastBaselineAnchor, constant: 8)

        self.messagePreferredTopConstraint = self.messageLabel.firstBaselineAnchor.constraint(greaterThanOrEqualTo: self.imageView.bottomAnchor, constant: 38.3871)
        self.messagePreferredTopConstraint.priority = UILayoutPriority(746)
        self.messageRequiredBottomConstraint = self.contentView.bottomAnchor.constraint(equalTo: self.messageLabel.lastBaselineAnchor, constant: 8)

        let contentHeightExpanderConstraint = self.contentScrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: self.contentView.heightAnchor)
        contentHeightExpanderConstraint.priority = UILayoutPriority(749)

        self.buttonHeightPreferredConstraint = self.buttonScrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: self.buttonStackView.heightAnchor, constant: 32)
        self.buttonHeightPreferredConstraint.priority = UILayoutPriority(749)

        self.buttonHeightRequiredConstraint = self.buttonScrollView.heightAnchor.constraint(greaterThanOrEqualToConstant: 32 + 48)

        // When push comes to shove, prefer to give the content 2/3rds of the view
        self.divvierUpperConstraint = self.contentScrollView.heightAnchor.constraint(equalTo: self.buttonScrollView.heightAnchor, multiplier: 2)
        self.divvierUpperConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            self.backgroundView.topAnchor.constraint(equalTo: self.topAnchor),
            self.backgroundView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            self.backgroundView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            self.backgroundView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.backgroundView.contentView.topAnchor.constraint(equalTo: self.backgroundView.topAnchor),
            self.backgroundView.contentView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor),
            self.backgroundView.contentView.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor),
            self.backgroundView.contentView.bottomAnchor.constraint(equalTo: self.backgroundView.bottomAnchor),

            self.contentScrollView.topAnchor.constraint(equalTo: self.backgroundView.topAnchor),
            self.contentScrollView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor),
            self.contentScrollView.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor),
            self.contentScrollView.bottomAnchor.constraint(equalTo: self.buttonScrollView.topAnchor),
            self.buttonScrollView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor),
            self.buttonScrollView.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor),
            self.buttonScrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor),

            self.contentView.topAnchor.constraint(equalTo: self.contentScrollView.contentLayoutGuide.topAnchor),
            self.contentView.leadingAnchor.constraint(equalTo: self.contentScrollView.frameLayoutGuide.leadingAnchor),
            self.contentView.trailingAnchor.constraint(equalTo: self.contentScrollView.frameLayoutGuide.trailingAnchor),
            self.contentView.bottomAnchor.constraint(equalTo: self.contentScrollView.contentLayoutGuide.bottomAnchor),

            self.gradientView.heightAnchor.constraint(equalToConstant: 2),
            self.gradientView.leadingAnchor.constraint(equalTo: self.backgroundView.leadingAnchor),
            self.gradientView.trailingAnchor.constraint(equalTo: self.backgroundView.trailingAnchor),
            self.gradientView.bottomAnchor.constraint(equalTo: self.contentScrollView.bottomAnchor),

            self.imageTopConstraint,
            self.imageLeadingConstraint,
            self.imageTrailingConstraint,
            self.contentView.bottomAnchor.constraint(greaterThanOrEqualTo: self.imageView.bottomAnchor),

            self.altTextLabel.topAnchor.constraint(equalToSystemSpacingBelow: self.imageView.topAnchor, multiplier: 1),
            self.altTextLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: self.imageView.leadingAnchor, multiplier: 1),
            self.imageView.trailingAnchor.constraint(equalToSystemSpacingAfter: self.altTextLabel.trailingAnchor, multiplier: 1),
            self.altTextBottomConstraint,

            self.titleLabel.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            self.titleLabel.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 1, constant: -60),
            self.titleRequiredTopConstraint,
            self.titlePreferredTopConstraint,
            self.titleRequiredBottomConstraint,

            self.messageLabel.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            self.messageLabel.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 1, constant: -60),
            self.messagePreferredTopConstraint,
            self.titleMessageSpaceMinimumConstraint,
            self.titleMessageSpacePreferredConstraint,
            self.titleMessageSpaceMaximumConstraint,
            self.messageRequiredBottomConstraint,

            contentHeightExpanderConstraint,

            self.buttonStackView.topAnchor.constraint(equalTo: self.buttonScrollView.contentLayoutGuide.topAnchor, constant: 16),
            self.buttonStackView.leadingAnchor.constraint(equalTo: self.buttonScrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            self.buttonStackView.trailingAnchor.constraint(equalTo: self.buttonScrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            self.buttonStackView.bottomAnchor.constraint(equalTo: self.buttonScrollView.contentLayoutGuide.bottomAnchor, constant: -16),

            self.buttonHeightPreferredConstraint,
            self.buttonHeightRequiredConstraint,

            self.divvierUpperConstraint,
        ])

        self.handleDynamicTypeChange()
    }

    func handleDynamicTypeChange() {
        // See if two buttons fit side-by-side
        if self.buttonStackView.arrangedSubviews.count == 2 {
            guard let leadingButton = self.buttonStackView.arrangedSubviews.first, let trailingButton = self.buttonStackView.arrangedSubviews.last else {
                return
            }

            let leadingMinSize = leadingButton.systemLayoutSizeFitting(.init(width: 140, height: 48)).width
            let trailingMinSize = trailingButton.systemLayoutSizeFitting(.init(width: 140, height: 48)).width

            if leadingMinSize <= 140 && trailingMinSize <= 140 {
                self.buttonStackView.axis = .horizontal
                self.buttonStackView.distribution = .fillEqually
                self.buttonHeightPreferredConstraint.isActive = false
            } else {
                self.buttonStackView.axis = .vertical
                self.buttonHeightPreferredConstraint.isActive = true
            }
        }

        // Scale up/down the spacing
        self.titleRequiredTopConstraint.constant = self.headingFontMetrics.scaledValue(for: 38.3871, compatibleWith: self.traitCollection)
        self.titlePreferredTopConstraint.constant = self.headingFontMetrics.scaledValue(for: 38.3871, compatibleWith: self.traitCollection)
        self.titleMessageSpaceMinimumConstraint.constant = self.headingFontMetrics.scaledValue(for: 18.6677, compatibleWith: self.traitCollection)
        self.titleMessageSpacePreferredConstraint.constant = self.headingFontMetrics.scaledValue(for: 25.9004, compatibleWith: self.traitCollection)
        self.titleMessageSpaceMaximumConstraint.constant = self.headingFontMetrics.scaledValue(for: 25.9004, compatibleWith: self.traitCollection)
        self.buttonHeightRequiredConstraint.constant = self.bodyFontMetrics.scaledValue(for: 48, compatibleWith: self.traitCollection) + 32
    }

    class GradientView: UIView {
        override class var layerClass: AnyClass {
            return CAGradientLayer.self
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()

            guard let gradientLayer = self.layer as? CAGradientLayer else {
                return
            }

            gradientLayer.colors = [UIColor(white: 0, alpha: 0).cgColor, UIColor(white: 0, alpha: 0.045).cgColor]
            gradientLayer.startPoint = .init(x: 0.5, y: 0)
            gradientLayer.endPoint = .init(x: 0.5, y: 1)
        }
    }
}
