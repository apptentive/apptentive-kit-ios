//
//  SceneDelegate.swift
//  Example
//
//  Created by Frank Schmitt on 6/23/21.
//

import UIKit
import ApptentiveKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UITabBarControllerDelegate {
    var window: UIWindow?

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        (windowScene.windows.first?.rootViewController as? UITabBarController)?.delegate = self
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let navigationController = viewController as? UINavigationController, let photosViewController = navigationController.topViewController as? PhotosViewController else {
            return
        }

        if photosViewController.onlyShowFavorites {
            Apptentive.shared.engage(event: "favorite_photos", from: viewController)
        } else {
            Apptentive.shared.engage(event: "all_photos", from: viewController)
        }
    }
}

