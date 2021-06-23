//
//  SurveyIndicator.swift
//  SurveyCard
//
//  Created by Frank Schmitt on 5/4/21.
//

// TODO: Handle Right-to-left
// TODO: Handle continuous mode
// TODO: Condense spacing?

import UIKit

@IBDesignable
class SurveyIndicator: UIView {
    @IBInspectable var numberOfSegments: Int = 1 {
        didSet {
            if self.numberOfSegments < 1 {
                self.numberOfSegments = 1
            }

            self.recreateSegments()
        }
    }

    @IBInspectable var selectedSegmentIndex: Int = 0 {
        didSet {
            self.updateSegmentStyles()
            self.layoutSublayers(of: layer)
        }
    }

    @IBInspectable var unselectedEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: 1, left: 0, bottom: 1, right: 0) {
        didSet {
            self.layoutSublayers(of: layer)
        }
    }

    var enabledSegments = IndexSet() {
        didSet {
            self.updateSegmentStyles()
        }
    }

////    enum Mode {
////        case salient
////        case smooth
////    }
////
////    var mode: Mode {
////        let minimumSalientWidth = CGFloat(self.numberOfSegments) * self.minimumSegmentWidth + CGFloat(self.numberOfSpaces) * self.minimumSegmentSpacing
////
////        return self.bounds.width >= minimumSalientWidth ? .salient : .smooth
////    }
//
    private let defaultSegmentWidth: CGFloat = 32
    private let minimumSegmentWidth: CGFloat = 16
    private let defaultSegmentSpacing: CGFloat = 8
    private let minimumSegmentSpacing: CGFloat = 4
    private let defaultHeight: CGFloat = 4

    private var segmentLayers = [CALayer]()

    private var numberOfSpaces: Int {
        numberOfSegments - 1
    }

    private var maximumWidth: CGFloat {
        return CGFloat(self.numberOfSegments) * self.defaultSegmentWidth + CGFloat(self.numberOfSpaces) * self.defaultSegmentSpacing
    }

    private var minimumWidth: CGFloat {
        return CGFloat(self.numberOfSegments) * self.minimumSegmentWidth + CGFloat(self.numberOfSpaces) * self.minimumSegmentSpacing
    }

    private var segmentWidth: CGFloat {
        if self.bounds.width >= maximumWidth {
            return self.defaultSegmentWidth
        } else if self.bounds.width <= minimumWidth {
            return self.minimumSegmentWidth
        } else {
            return self.defaultSegmentWidth * self.bounds.width / self.maximumWidth
        }
    }

    private var segmentSpacing: CGFloat {
        if self.bounds.width >= maximumWidth {
            return self.defaultSegmentSpacing
        } else if self.bounds.width <= minimumWidth {
            return self.minimumSegmentSpacing
        } else {
            return self.defaultSegmentSpacing * self.bounds.width / self.maximumWidth
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: self.maximumWidth, height: self.defaultHeight)
    }

    override func layoutSublayers(of layer: CALayer) {
        if layer == self.layer {
            var left: CGFloat = max(self.bounds.size.width - self.maximumWidth, 0) / 2

            for (index, layer) in self.segmentLayers.enumerated() {
                let frame = CGRect(x: left, y: 0, width: self.segmentWidth, height: self.bounds.height)

                if index == self.selectedSegmentIndex {
                    layer.frame = frame
                } else {
                    layer.frame = frame.inset(by: self.unselectedEdgeInsets)
                }

                layer.cornerRadius = min(layer.frame.height, layer.frame.width) / 2

                left += self.segmentWidth + self.segmentSpacing
            }
        } else {
            super.layoutSublayers(of: layer)
        }
    }

    private func recreateSegments() {
        self.segmentLayers.forEach { layer in
            layer.removeFromSuperlayer()
        }

        self.segmentLayers.removeAll()

        for _ in 0..<self.numberOfSegments {
            let segmentLayer = CALayer();

            self.layer.addSublayer(segmentLayer)
            self.segmentLayers.append(segmentLayer)
        }

        self.layoutSublayers(of: self.layer)
        self.updateSegmentStyles()
    }

    private func updateSegmentStyles() {
        for (index, layer) in self.segmentLayers.enumerated() {
            if index == self.selectedSegmentIndex {
                layer.backgroundColor = self.tintColor.cgColor
            } else if self.enabledSegments.contains(index) {
                layer.backgroundColor = UIColor.gray.cgColor
            } else {
                layer.backgroundColor = UIColor.lightGray.cgColor
            }
        }
    }
}
