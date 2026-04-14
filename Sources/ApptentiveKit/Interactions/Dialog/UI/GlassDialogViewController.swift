//
//  DialogViewController.swift
//  AlertController
//
//  Created by Frank Schmitt on 8/1/25.
//

import UIKit


@available(iOS 26, *)
class GlassDialogViewController: UIViewController, UIGestureRecognizerDelegate, DialogViewModelDelegate {
    let viewModel: DialogViewModel
    let dialogView: GlassDialogView
    var verticalPositionConstraint = NSLayoutConstraint()

    init(viewModel: DialogViewModel) {
        self.viewModel = viewModel

        self.dialogView = GlassDialogView()

        super.init(nibName: nil, bundle: nil)

        viewModel.delegate = self

        self.modalPresentationStyle = .overFullScreen
        self.modalTransitionStyle = .crossDissolve
    }

    override func viewDidLoad() {
        self.view.backgroundColor = UIColor(white: 0, alpha: 0.2)  // Dimming view

        self.dialogView.translatesAutoresizingMaskIntoConstraints = false

        self.view.addSubview(self.dialogView)

        self.dialogView.titleLabel.attributedString = self.viewModel.title
        self.dialogView.messageLabel.attributedString = self.viewModel.message

        for action in self.viewModel.actions {
            var button: GlassDialogButton

            switch action.actionType {
            case .dismiss:
                button = GlassDialogButton(frame: .zero)
            case .interaction:
                button = GlassDialogButton(frame: .zero)
            case .yes:
                button = GlassDialogButton(frame: .zero)
            case .no:
                button = GlassDialogButton(frame: .zero)
            }

            button.text = action.label
            button.completion = {
                action.buttonTapped()

                self.dismiss(animated: true)
            }

            self.dialogView.buttonStackView.addArrangedSubview(button)

            self.dialogView.gestureRecognizer.delegate = self
        }

        let upperSpaceConstraint = self.dialogView.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.viewModel.verticalMargins)
        let lowerSpaceConstraint = self.view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualTo: self.dialogView.bottomAnchor, constant: self.viewModel.verticalMargins)
        let preferredHeightConstraint = self.dialogView.heightAnchor.constraint(equalToConstant: 48)
        preferredHeightConstraint.priority = .init(500)

        switch self.viewModel.position {
        case .top:
            self.verticalPositionConstraint = self.dialogView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: self.viewModel.verticalMargins)

        case .center:
            self.verticalPositionConstraint = self.dialogView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)

        case .bottom:
            self.verticalPositionConstraint = self.dialogView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -self.viewModel.verticalMargins)

        }
        self.verticalPositionConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            self.dialogView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.verticalPositionConstraint,
            self.dialogView.widthAnchor.constraint(equalToConstant: 320),
            preferredHeightConstraint,
            upperSpaceConstraint,
            lowerSpaceConstraint,
        ])

        self.dialogView.titleLabel.isHidden = self.viewModel.isTitleHidden
        self.dialogView.messageLabel.isHidden = self.viewModel.isMessageHidden
        self.dialogView.imageView.isHidden = self.viewModel.dialogContainsImage

        if self.viewModel.isTitleHidden || self.viewModel.isMessageHidden {
            // If only one label (out of title/message) is visible, iOS 26
            // center-aligns the surviving label and uses a font with text
            // style of `body` and the `label` system color.

            // This copies that behavior and uses the title color for the
            // surviving label (if any).
            self.dialogView.messageLabel.textAlignment = .center
            self.dialogView.messageLabel.font = .apptentiveDialogText
            self.dialogView.messageLabel.textColor = .apptentiveDialogTitle

            self.dialogView.titleLabel.textAlignment = .center
            self.dialogView.titleLabel.font = .apptentiveDialogText

            // Remove spacer constraints to avoid layout weirdness.
            self.dialogView.titleMessageSpaceMaximumConstraint.isActive = false
            self.dialogView.titleMessageSpaceMinimumConstraint.isActive = false
            self.dialogView.titleMessageSpacePreferredConstraint.isActive = false
            self.dialogView.divvierUpperConstraint.isActive = false

            if self.viewModel.isTitleHidden {
                // Remove constraints that tie the (hidden) title to top.
                self.dialogView.titleRequiredTopConstraint.isActive = false
                self.dialogView.titlePreferredTopConstraint.isActive = false
                self.dialogView.titleRequiredBottomConstraint.isActive = false
            }

            if self.viewModel.isMessageHidden {
                // Remove constraints that tie (hidden) message to bottom.
                self.dialogView.messageRequiredBottomConstraint.isActive = false
            }
        }

        self.dialogViewModel(self.viewModel, didLoadImage: self.viewModel.image)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        self.dialogView.setNeedsLayout()
        self.dialogView.layoutIfNeeded()

        let contentFits = floor(self.dialogView.contentScrollView.contentSize.height) <= self.dialogView.contentScrollView.bounds.height
        self.dialogView.gradientView.isHidden = contentFits
        self.dialogView.contentScrollView.isScrollEnabled = !contentFits

        self.dialogView.handleDynamicTypeChange()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        self.dialogView.setScale(1.2, animated: false)
        self.dialogView.setScale(1, animated: true)
    }

    public override func viewDidAppear(_ animated: Bool) {
        UIAccessibility.post(notification: .announcement, argument: NSLocalizedString("Dialog announcement", bundle: .main, value: "Alert", comment: "Announcement when a dialog is presented."))

        let contentFits = floor(self.dialogView.contentScrollView.contentSize.height) <= self.dialogView.contentScrollView.bounds.height
        self.dialogView.gradientView.isHidden = contentFits
        self.dialogView.contentScrollView.isScrollEnabled = !contentFits

        self.dialogView.handleDynamicTypeChange()
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Allow simultaneous recognition with scroll view gestures
        if otherGestureRecognizer.view is UIScrollView {
            return true
        }

        return false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Dialog View Model Delegate

    // swift-format-ignore
    public func dismiss() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    public func dialogViewModel(_: DialogViewModel, didLoadImage imageData: DialogViewModel.Image) {
        switch imageData {
        case .loaded(let image, let accessibilityLabel, let layout):
            self.dialogView.altTextLabel.text = nil
            self.dialogView.altTextBottomConstraint.isActive = false

            self.dialogView.imageView.image = image
            self.dialogView.imageView.accessibilityLabel = accessibilityLabel
            self.dialogView.imageView.isAccessibilityElement = true
            self.dialogView.imageView.contentMode = layout.contentMode(for: self.traitCollection)
            self.dialogView.imageView.isHidden = false
            self.layoutImage(for: image, with: layout)

        case .loading(let altText, let layout):
            self.dialogView.altTextLabel.text = altText
            self.dialogView.imageView.image = nil
            self.dialogView.imageView.accessibilityLabel = nil
            self.dialogView.imageView.isAccessibilityElement = false
            self.layoutImage(for: nil, with: layout)

        case .none:
            self.dialogView.altTextLabel.text = nil
            self.dialogView.altTextBottomConstraint.isActive = false

            self.dialogView.imageView.image = nil
            self.dialogView.imageView.accessibilityLabel = nil
            self.dialogView.imageView.isAccessibilityElement = false
            self.dialogView.imageView.isHidden = true
            self.layoutImage(for: nil, with: nil)
        }
    }

    // MARK: - Private

    private func layoutImage(for image: UIImage?, with layout: DialogViewModel.Image.Layout?) {
        if let image = image, layout == .fullWidth && image.size.width > 0 && image.size.height > 0 {
            let imageAspectRatio = image.size.height / image.size.width

            self.dialogView.setImageAspectRatio(imageAspectRatio)
        } else if layout != nil && layout != .fullWidth {
            self.dialogView.imageTopConstraint.constant = 20
            self.dialogView.imageLeadingConstraint.constant = 20
            self.dialogView.imageTrailingConstraint.constant = 20
        }

        if let layout = layout {
            self.dialogView.imageView.contentMode = layout.contentMode(for: self.traitCollection)
        }
    }
}
