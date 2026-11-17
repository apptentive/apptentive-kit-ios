//
//  SurveyPageIndicatorView.swift
//  ApptentiveKit
//
//  Created by Frank Schmitt on 6/15/26.
//  Copyright © 2026 Apptentive, Inc. All rights reserved.
//

import UIKit

/// Shows discrete pill segments for surveys with ≤10 pages, or a continuous progress bar for longer surveys.
///
/// Sizes match the old UIKit survey indicator.
class SurveyPageIndicatorView: UIView {

    private static let segmentThreshold = 10
    private static let segmentWidth: CGFloat = 50
    private static let segmentSpacing: CGFloat = 15
    private static let unselectedSegmentHeight: CGFloat = 3
    private static let selectedSegmentHeight: CGFloat = 6
    private static let progressBarHeight: CGFloat = 6
    private static let progressBarMaxWidth: CGFloat = 350

    private let segmentCount: Int
    private var segmentViews: [Segment] = []
    private var segmentHeightConstraints: [NSLayoutConstraint] = []
    private var progressView: UIProgressView?

    init(segmentCount: Int) {
        self.segmentCount = segmentCount
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        if segmentCount <= Self.segmentThreshold {
            setupSegments()
        } else {
            setupProgressBar()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: max(Self.selectedSegmentHeight, Self.progressBarHeight))
    }

    func setPage(_ page: Int, animated: Bool, duration: TimeInterval = 0.35) {
        if !segmentViews.isEmpty {
            let update = {
                for (index, segment) in self.segmentViews.enumerated() {
                    let isSelected = index == page
                    segment.backgroundColor = isSelected ? .apptentiveSelectedSurveyIndicatorSegment : .apptentiveUnselectedSurveyIndicatorSegment
                    self.segmentHeightConstraints[index].constant = isSelected ? Self.selectedSegmentHeight : Self.unselectedSegmentHeight
                }
                self.layoutIfNeeded()
            }
            if animated {
                UIView.animate(withDuration: 0.2, animations: update)
            } else {
                update()
            }
        } else {
            let progress = Float(page + 1) / Float(segmentCount)
            if animated {
                CATransaction.begin()
                CATransaction.setAnimationDuration(duration)
                CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
                progressView?.setProgress(progress, animated: true)
                CATransaction.commit()
            } else {
                progressView?.setProgress(progress, animated: false)
            }
        }
    }

    private func setupSegments() {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = Self.segmentSpacing
        addSubview(stackView)

        for _ in 0..<segmentCount {
            let segment = Segment()
            segment.backgroundColor = .apptentiveUnselectedSurveyIndicatorSegment
            segment.translatesAutoresizingMaskIntoConstraints = false
            // Segments keep their preferred width unless the row doesn't fit, then shrink evenly.
            segment.setContentHuggingPriority(.required, for: .horizontal)
            segment.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let heightConstraint = segment.heightAnchor.constraint(equalToConstant: Self.unselectedSegmentHeight)
            heightConstraint.isActive = true
            segmentHeightConstraints.append(heightConstraint)
            segmentViews.append(segment)
            stackView.addArrangedSubview(segment)
        }

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor, constant: 8),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: Self.selectedSegmentHeight),
        ])
    }

    private func setupProgressBar() {
        let pv = UIProgressView(progressViewStyle: .bar)
        pv.progressTintColor = .apptentiveSelectedSurveyIndicatorSegment
        pv.trackTintColor = .apptentiveUnselectedSurveyIndicatorSegment
        pv.layer.cornerRadius = Self.progressBarHeight * 0.25
        pv.clipsToBounds = true
        pv.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pv)

        let preferredWidth = pv.widthAnchor.constraint(equalToConstant: Self.progressBarMaxWidth)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            preferredWidth,
            pv.widthAnchor.constraint(lessThanOrEqualToConstant: Self.progressBarMaxWidth),
            pv.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            trailingAnchor.constraint(greaterThanOrEqualTo: pv.trailingAnchor, constant: 8),
            pv.centerXAnchor.constraint(equalTo: centerXAnchor),
            pv.centerYAnchor.constraint(equalTo: centerYAnchor),
            pv.heightAnchor.constraint(equalToConstant: Self.progressBarHeight),
        ])
        progressView = pv
    }

    /// A pill-shaped segment whose corner radius follows its (animated) height.
    private final class Segment: UIView {
        override var intrinsicContentSize: CGSize {
            CGSize(width: SurveyPageIndicatorView.segmentWidth, height: UIView.noIntrinsicMetric)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            layer.cornerRadius = bounds.height / 2
        }
    }
}
