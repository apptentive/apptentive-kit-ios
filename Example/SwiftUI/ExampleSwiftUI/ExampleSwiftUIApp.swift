//
//  ExampleSwiftUIApp.swift
//  ExampleSwiftUI
//
//  Created by Frank Schmitt on 5/3/23.
//

import SwiftUI
import ApptentiveKit

@main
struct ExampleSwiftUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State private var photoManager = PhotoManager.shared

    var body: some Scene {
        WindowGroup {
            GalleryView()
                .environment(photoManager)
                .tint(.red)
        }
    }

    init() {
        PhotoManager.shared.load()
    }
}
