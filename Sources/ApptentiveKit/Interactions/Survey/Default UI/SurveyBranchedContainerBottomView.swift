//
//  SurveyBranchedContainerBottomView.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 7/25/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

class SurveyBranchedContainerBottomView: UIView {

    let bottomView: SurveyBranchedBottomView

    override init(frame: CGRect) {
        self.bottomView = SurveyBranchedBottomView(frame: frame)
        super.init(frame: frame)
        self.addSubview(self.bottomView)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .apptentiveSubmitButton
        self.setConstraints()
    }

    init(frame: CGRect, numberOfSegments: Int) {
        self.bottomView = SurveyBranchedBottomView(frame: frame, numberOfSegments: numberOfSegments)
        super.init(frame: frame)
        self.addSubview(self.bottomView)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = .apptentiveSubmitButton
        self.setConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let safeArea = self.bounds.inset(by: self.safeAreaInsets)

        let composeViewSize = self.bottomView.systemLayoutSizeFitting(safeArea.size, withHorizontalFittingPriority: .fittingSizeLevel, verticalFittingPriority: .defaultHigh)

        return CGSize(width: composeViewSize.width + self.safeAreaInsets.left + self.safeAreaInsets.right, height: composeViewSize.height + self.safeAreaInsets.bottom)
    }

    private func setConstraints() {
        self.bottomView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: self.bottomView.topAnchor),
            self.leadingAnchor.constraint(equalTo: self.bottomView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: self.bottomView.trailingAnchor),
            self.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: self.bottomView.bottomAnchor),
        ])
    }
}
