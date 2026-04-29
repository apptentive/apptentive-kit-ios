//
//  ContentView.swift
//  ExampleSwiftUI
//
//  Created by Frank Schmitt on 5/3/23.
//

import SwiftUI
import ApptentiveKit

struct GalleryView: View {
    @Environment(PhotoManager.self) private var photoManager
    @State private var selectedTabIndex = 0

    var body: some View {
        TabView(selection: $selectedTabIndex) {
            NavigationStack() {
                PhotoListView(photoList: photoManager.allItems)
                    .navigationTitle("Photos")
            }
            .tabItem {
                Label("Photos", systemImage: "photo")
            }
            .tag(1)

            NavigationStack() {
                PhotoListView(photoList: photoManager.favoriteItems)
                    .navigationTitle("Favorites")
            }
            .tabItem {
                Label("Favorites", systemImage: "heart")
            }
            .tag(2)
        }.onChange(of: selectedTabIndex) { _, newValue in
            if newValue == 2 {
                Apptentive.shared.engage(event: "favorite_photos")
            } else {
                Apptentive.shared.engage(event: "all_photos")
            }
        }
    }
}

#Preview {
    let photoManager = {
        let result = PhotoManager()

        result.load()

        return result
    }()

    GalleryView()
        .environment(photoManager)
}
