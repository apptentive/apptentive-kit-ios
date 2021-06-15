//
//  UIWindow+TopViewController.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 5/25/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import UIKit

extension UIWindow {
    var topViewController: UIViewController? {
        if let rootViewController = self.rootViewController {
            return Self.findTopViewController(of: rootViewController)
        } else {
            return nil
        }
    }

    private class func findTopViewController(of viewController: UIViewController) -> UIViewController {
        switch viewController {
        case let navigationController as UINavigationController:
            if let visibleViewController = navigationController.visibleViewController {
                return findTopViewController(of: visibleViewController)
            } else {
                return navigationController
            }

        case let tabBarController as UITabBarController:
            if let selectedViewController = tabBarController.selectedViewController {
                return findTopViewController(of: selectedViewController)
            } else {
                return tabBarController
            }

        default:
            if let presentedViewController = viewController.presentedViewController {
                return findTopViewController(of: presentedViewController)
            } else {
                return viewController
            }
        }
    }
}
