//
//  DialogButton.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 9/21/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

/// The buttons used in TextModal ("Note") and EnjoymentDialog ("Love Dialog") interactions.
public class DialogButton: UIButton {
    // MARK: - Appearance

    /// The font to use for the button title.
    @objc public dynamic var titleFont: UIFont = .preferredFont(forTextStyle: .body)

    /// The radius of the button corners.
    ///
    /// Setting the radius to -1 will set the radius to half of the hieght of the button.
    @objc public dynamic var cornerRadius: CGFloat = 0

    /// The width of the border of the button.
    @objc public dynamic var borderWidth: CGFloat = 0

    /// The color of the border of the button.
    @objc public dynamic var borderColor: UIColor = .clear

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setTitleColor(.apptentiveTint, for: .normal)
        self.titleLabel?.adjustsFontSizeToFitWidth = true
        self.titleLabel?.minimumScaleFactor = 0.58
        self.titleLabel?.adjustsFontForContentSizeCategory = true

        self.configuration = .plain()
        self.configuration?.contentInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
        self.configuration?.titleLineBreakMode = .byTruncatingMiddle
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // swift-format-ignore
    public override var intrinsicContentSize: CGSize {
        return CGSize(width: 270, height: 45)
    }

    // swift-format-ignore
    public override func layoutSubviews() {
        super.layoutSubviews()

        if self.cornerRadius == -1 {
            self.layer.cornerRadius = self.bounds.height / 2
        }
    }

    // swift-format-ignore
    public override func didMoveToWindow() {
        super.didMoveToWindow()

        self.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            let fontDescriptor = self.titleFont.fontDescriptor
            let newFont = UIFont(descriptor: fontDescriptor, size: self.titleFont.pointSize)
            outgoing.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: newFont)
            return outgoing
        }

        if self.cornerRadius >= 0 {
            self.layer.cornerRadius = self.cornerRadius
        }

        self.layer.borderColor = self.borderColor.cgColor
        self.layer.borderWidth = self.borderWidth
    }
}

/// A button used to dismiss a TextModal ("Note") interaction.
public class DismissButton: DialogButton {}

/// A button used to launch a subsequent interaction from a TextModal ("Note") interaction.
public class InteractionButton: DialogButton {}

/// A button used to indicate positive sentiment in the EnjoymentDialog ("Love Dialog") interaction.
public class YesButton: DialogButton {}

/// A button used to indicate negative sentiment in the EnjoymentDialog ("Love Dialog") interaction.
public class NoButton: DialogButton {}
