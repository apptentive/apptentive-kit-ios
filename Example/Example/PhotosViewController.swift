//
//  PhotosViewController.swift
//  Example
//
//  Created by Frank Schmitt on 6/24/21.
//

import UIKit
import Combine
import ApptentiveKit

class PhotosViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    @objc var onlyShowFavorites: Bool = false
    @IBOutlet var emptyLabel: UILabel?

    enum Section {
        case main
    }

    var dataSource: UICollectionViewDiffableDataSource<Section, PhotoManager.Photo>!
    var pictureSubscription: AnyCancellable!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = UICollectionViewDiffableDataSource<Section, PhotoManager.Photo>(collectionView: self.collectionView, cellProvider: { collectionView, indexPath, picture in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Picture", for: indexPath) as! PhotoCell

            cell.imageView.image = picture.image

            cell.heartButton.isSelected = picture.isFavorite
            cell.heartButton.tintColor = picture.isFavorite ? .systemRed : .white
            cell.heartButton.removeTarget(nil, action: nil, for: .allEvents)
            cell.heartButton.addTarget(self, action: #selector(self.toggleFavorite(_:)), for: .touchUpInside)
            cell.heartButton.tag = picture.tag

            return cell
        })

        let picturePublisher = self.onlyShowFavorites ? PhotoManager.shared.$favoriteItems : PhotoManager.shared.$allItems

        self.pictureSubscription = picturePublisher.receive(on: DispatchQueue.main).sink { pictures in
            var snapshot = NSDiffableDataSourceSnapshot<Section, PhotoManager.Photo>()
            snapshot.appendSections([.main])
            snapshot.appendItems(pictures)
            self.dataSource.apply(snapshot)

            self.emptyLabel?.isHidden = pictures.count > 0
        }

        self.collectionView.backgroundView = self.emptyLabel

        PhotoManager.shared.update()

        DispatchQueue.global().async {
            PhotoManager.shared.load()
        }
    }

    deinit {
        self.pictureSubscription.cancel()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate { context in
            self.collectionViewLayout.invalidateLayout()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = self.collectionViewLayout as! UICollectionViewFlowLayout

        let preferredMaxWidth: CGFloat = 320
        let preferredMaxHeight = self.collectionView.bounds.height

        let horizontalCount: CGFloat = floor(self.collectionView.bounds.width / preferredMaxWidth)
        let verticalCount: CGFloat = ceil(self.collectionView.bounds.width / preferredMaxHeight)

        let count = max(horizontalCount, verticalCount)

        let size = (collectionView.bounds.width
            - flowLayout.sectionInset.left
            - flowLayout.sectionInset.right
            - flowLayout.minimumInteritemSpacing * (count - 1))
            / count

        return CGSize(width: size, height: size)
    }

    @objc func toggleFavorite(_ sender: UIButton) {
        PhotoManager.shared.toggleFavorite(for: sender.tag)

        Apptentive.shared.engage(event: "toggle_favorite", from: self)
    }
}
