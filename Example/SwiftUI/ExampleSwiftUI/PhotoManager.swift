//
//  PhotoManager.swift
//  Example
//
//  Created by Frank Schmitt on 6/24/21.
//

import UIKit
import Observation

@Observable
@MainActor
class PhotoManager {
    struct Photo: Hashable, Identifiable {
        var id: Int { tag }
        let image: UIImage
        let tag: Int
        var isFavorite: Bool
    }

    @ObservationIgnored private let imageURLs: [URL]
    @ObservationIgnored private var images = [UIImage]()

    private static let userDefaultsKey = "FavoritePhotos"

    static let shared = PhotoManager()

    var allItems = [Photo]() {
        didSet {
            self.favoriteItems = self.allItems.filter { $0.isFavorite }
            UserDefaults.standard.set(self.favoriteItems.map { $0.tag }, forKey: Self.userDefaultsKey)
        }
    }

    var favoriteItems = [Photo]()

    init() {
        self.imageURLs = Bundle.main.urls(forResourcesWithExtension: "jpg", subdirectory: "Photos") ?? []
    }

    func load() {
        self.images = self.imageURLs.compactMap { url in
            UIImage(contentsOfFile: url.path)
        }

        let defaultFavorites = Set(UserDefaults.standard.array(forKey: Self.userDefaultsKey) as? [Int] ?? [])

        self.allItems = self.images.enumerated().map { (index, image) in
            return Photo(image: image, tag: index, isFavorite: defaultFavorites.contains(index))
        }
    }

    func setFavorite(_ isFavorite: Bool, for tag: Int) {
        self.allItems[tag].isFavorite = isFavorite
    }
}

