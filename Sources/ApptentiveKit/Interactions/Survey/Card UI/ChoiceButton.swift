//
//  ChoiceButton.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 5/28/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

class ChoiceButton: UIButton {
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        let height = self.titleLabel?.bounds.height ?? 0 + self.titleEdgeInsets.top + titleEdgeInsets.bottom

        return CGSize(width: superSize.width, height: height)
    }
}
