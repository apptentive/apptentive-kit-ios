//
//  SurveyIndicator.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 8/2/22.
//  Copyright © 2022 Apptentive, Inc. All rights reserved.
//

import UIKit

class SurveyIndicator: UIControl {

    var numberOfSegments: Int

    var segments: [UIView] = []

    var currentSelectedSetIndex: Int = 0 {
        willSet {
            self.previousSelectedIndex = currentSelectedSetIndex
        }

        didSet {
            self.updateSelectedSegmentAppearance()
        }
    }

    var previousSelectedIndex: Int = 0

    var progressBar: ProgressBar?

    var stackView: UIStackView

    var heightConstraintsForView: [UIView: NSLayoutConstraint] = [:]

    var progressIncrement: CGFloat {
        let standardIncrement: CGFloat = CGFloat(self.numberOfSegments) / CGFloat(self.numberOfSegments * numberOfSegments)

        let selectedIndexDiff = CGFloat(self.currentSelectedSetIndex - self.previousSelectedIndex)
        let selectedIndexDiffMultple = selectedIndexDiff / 100
        let skipAmount = standardIncrement + (selectedIndexDiffMultple)

        if selectedIndexDiff > 1 {
            let skippedIncrement = (standardIncrement + skipAmount)
            return skippedIncrement
        } else {
            return standardIncrement
        }
    }

    override init(frame: CGRect) {
        self.stackView = UIStackView(frame: .zero)
        self.numberOfSegments = 0
        self.progressBar = nil
        super.init(frame: frame)
        self.configureSegments()
        self.configureStackView()
        self.setConstraints()

    }

    required init?(coder aDecoder: NSCoder) {
        self.stackView = UIStackView(frame: .zero)
        self.numberOfSegments = 0
        self.progressBar = nil
        super.init(coder: aDecoder)
    }

    init(frame: CGRect, numberOfSegments: Int) {
        self.stackView = UIStackView(frame: .zero)
        self.numberOfSegments = numberOfSegments
        self.progressBar = nil
        if numberOfSegments > 10 {
            self.progressBar = ProgressBar(frame: .zero)
        }
        super.init(frame: frame)
        self.configureSegments()
        self.configureStackView()
        self.setConstraints()

    }

    private func configureSegments() {
        for var counter in 1...self.numberOfSegments {
            let segment = SurveyIndicatorSegment(frame: .zero)
            let segmentHeightConstraint: NSLayoutConstraint = segment.heightAnchor.constraint(equalToConstant: 3)
            NSLayoutConstraint.activate([
                segmentHeightConstraint
            ])
            self.heightConstraintsForView[segment] = segmentHeightConstraint
            self.segments.append(segment)
            counter += 1
        }
    }

    private func configureProgressBar() {
        guard let progressBar = progressBar else {
            return
        }
        progressBar.backgroundColor = .apptentiveUnselectedSurveyIndicatorSegment
        let progressBarHeightConstraint: NSLayoutConstraint = progressBar.heightAnchor.constraint(equalToConstant: 6)
        NSLayoutConstraint.activate([
            progressBarHeightConstraint
        ])

        self.stackView.addArrangedSubview(progressBar)
    }

    private func configureStackView() {
        self.addSubview(self.stackView)
        self.stackView.translatesAutoresizingMaskIntoConstraints = false
        self.stackView.alignment = .center
        self.stackView.axis = .horizontal
        self.stackView.distribution = .fillEqually
        self.stackView.spacing = 15
        if self.numberOfSegments > 10 {
            self.configureProgressBar()
        } else {
            self.segments.forEach { (segment) in
                self.stackView.addArrangedSubview(segment)
            }
        }
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            self.stackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
            self.bottomAnchor.constraint(equalTo: self.stackView.bottomAnchor, constant: 10),
            self.stackView.leadingAnchor.constraint(greaterThanOrEqualTo: self.readableContentGuide.leadingAnchor, constant: 8),
            self.readableContentGuide.trailingAnchor.constraint(greaterThanOrEqualTo: self.stackView.trailingAnchor, constant: 8),
            self.stackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
        ])
    }

    func updateSurveyIndicatorForThankYouScreen() {
        if self.numberOfSegments > 10 {
            self.progressBar?.isHidden = true
        } else {
            self.segments.forEach({ $0.isHidden = true })
        }
    }

    func updateSelectedSegmentAppearance() {

        if self.segments.count > 10 {
            guard let progressBar = progressBar else {
                return
            }

            progressBar.progress += self.progressIncrement

        } else {

            //Deselect previous selected segment before updating the UI for the new segment.
            if let segment = self.segments.first(where: { $0.backgroundColor == .apptentiveSelectedSurveyIndicatorSegment }) {
                UIView.animate(
                    withDuration: 0.2,
                    animations: {
                        if let currentHeightConstraint = self.heightConstraintsForView[segment] {
                            currentHeightConstraint.constant = 3

                        }
                        segment.backgroundColor = .apptentiveUnselectedSurveyIndicatorSegment
                    })
            }
        }

        //Update UI for selected segment.
        UIView.animate(
            withDuration: 0.2,
            animations: {
                let selectedSegment = self.segments[self.currentSelectedSetIndex]
                if let currentHeightConstraint = self.heightConstraintsForView[selectedSegment] {
                    currentHeightConstraint.constant = 6
                }
                selectedSegment.backgroundColor = .apptentiveSelectedSurveyIndicatorSegment
            })
    }
}

class SurveyIndicatorSegment: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setContentHuggingPriority(.required, for: .horizontal)
        self.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        self.backgroundColor = .apptentiveUnselectedSurveyIndicatorSegment
        self.translatesAutoresizingMaskIntoConstraints = false

    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 50, height: 3)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.bounds.height / 2
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ProgressBar: UIView {

    var progressColor: UIColor = .apptentiveSelectedSurveyIndicatorSegment {
        didSet { self.update() }
    }

    var progress: CGFloat = 0 {
        didSet { self.update() }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 350, height: 6)
    }

    let progressLayer = CALayer()
    let outerRectLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupLayers()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        //TODO: On iPad may need to increase 0.25 if line length is much greater.
        self.outerRectLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.bounds.size.height * 0.25).cgPath
        self.layer.mask = self.outerRectLayer
        self.update()
    }

    private func setupLayers() {
        self.layer.addSublayer(self.progressLayer)
    }

    private func update() {
        let progressRect = CGRect(origin: .zero, size: CGSize(width: self.bounds.size.width * self.progress, height: self.bounds.size.height))
        self.progressLayer.frame = progressRect
        self.progressLayer.backgroundColor = self.progressColor.cgColor
    }

}
