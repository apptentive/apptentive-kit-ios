//
//  DialogViewModel+Image.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 12/14/23.
//  Copyright © 2023 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

extension DialogViewModel {
    public enum Image {
        case none
        case loading(altText: String, layout: Layout)
        case loaded(image: UIImage, acessibilityLabel: String, layout: Layout, maxHeight: CGFloat)

        /// Describes the layout property of the image which will map to the UIImageView's content mode.
        public enum Layout: String {
            case fullWidth = "full_width"
            case leading = "align_left"
            case trailing = "align_right"
            case center = "center"

            func contentMode(for traitCollection: UITraitCollection) -> UIView.ContentMode {
                switch self {
                case .fullWidth:
                    return .scaleAspectFit

                case .leading:
                    return traitCollection.layoutDirection == .rightToLeft ? .right : .left

                case .trailing:
                    return traitCollection.layoutDirection == .rightToLeft ? .left : .right

                case .center:
                    return .center
                }
            }

            var imageInset: UIEdgeInsets {
                switch self {
                case .fullWidth:
                    return .zero

                default:
                    return UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
                }
            }
        }
    }
}
