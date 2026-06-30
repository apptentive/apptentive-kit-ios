//
//  PhotoManager.swift
//  Example
//
//  Created by Frank Schmitt on 6/24/21.
//

import UIKit
import Combine

class PhotoManager: ObservableObject {
    static let shared = PhotoManager()
    private static let userDefaultsKey = "FavoritePhotos"

    @Published var allItems = [Photo]()
    @Published var favoriteItems = [Photo]()

    private let imageURLs: [URL]
    private var images = [UIImage]()
    private var favorites: Set<Int> {
        didSet {
            self.update()

            UserDefaults.standard.set(Array(self.favorites), forKey: Self.userDefaultsKey)
        }
    }

    init() {
        self.imageURLs = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: nil) ?? []

        let defaultFavoritesArray = UserDefaults.standard.array(forKey: Self.userDefaultsKey) as? [Int]
        self.favorites = Set(defaultFavoritesArray ?? [])
    }

    func load() {
        self.images = self.imageURLs.compactMap { url in
            UIImage(contentsOfFile: url.path)
        }

        self.update()
    }

    func update() {
        self.allItems = images.enumerated().map { (index, image) in
            Photo(image: image, isFavorite: self.favorites.contains(index), tag: index)
        }

        self.favoriteItems = self.allItems.filter { $0.isFavorite }
    }

    func toggleFavorite(for tag: Int) {
        if self.favorites.contains(tag) {
            self.favorites.remove(tag)
        } else {
            self.favorites.insert(tag)
        }
    }
    
    struct Photo: Hashable {
        let image: UIImage
        let isFavorite: Bool
        let tag: Int
    }
}

