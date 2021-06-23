//
//  SurveyButton.swift
//  SurveyCard
//
//  Created by Frank Schmitt on 5/4/21.
//

import UIKit

@IBDesignable
class AdvanceButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = self.tintColor
        self.setTitleColor(.white, for: .normal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        let cornerSize = self.bounds.height / 2

        return CGSize(width: superSize.width + cornerSize * 2, height: superSize.height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerSize = min(self.bounds.width, self.bounds.height) / 2

        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: cornerSize, bottom: 0, right: cornerSize)
        self.layer.cornerRadius = cornerSize
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        self.backgroundColor = self.tintColor
    }
}
