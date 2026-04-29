//
//  PhotoListView.swift
//  ExampleSwiftUI
//
//  Created by Frank Schmitt on 5/3/23.
//

import SwiftUI

struct PhotoListView: View {
    @Environment(PhotoManager.self) private var photoManager
    var photoList: [PhotoManager.Photo]

    var body: some View {
        if photoList.isEmpty {
            ContentUnavailableView("No Photos", systemImage: "photo.on.rectangle.angled")
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                    ForEach(self.photoList) { photo in
                        PhotoCard(
                            isFavorite:
                                Binding(
                                    get: { photo.isFavorite },
                                    set: { photoManager.setFavorite($0, for: photo.tag) }
                                ),
                            image: photo.image
                        )

                    }
                }
                .animation(.default, value: photoList)
            }
        }
    }
}

#Preview("No Photos") {
    PhotoListView(photoList: [])
        .environment(PhotoManager())
}

#Preview("With Photos") { @MainActor in
    let photoManager = PhotoManager()
    photoManager.load()

    return PhotoListView(photoList: photoManager.allItems)
        .environment(photoManager)
}

