//
//  ApptentiveImageView.swift
//  ApptentiveKit
//
//  Created by Luqmaan Khan on 10/19/21.
//  Copyright © 2021 Apptentive, Inc. All rights reserved.
//

import Foundation
import UIKit

class ApptentiveImageView: UIImageView {

    private var dataTask: URLSessionDataTask?
    var url: URL? {
        didSet {
            if let url = self.url, url != oldValue {
                self.cancelTask()
                self.startTask(with: url)
            }
        }
    }

    override public init(image: UIImage? = nil) {
        super.init(image: image)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func startTask(with url: URL) {

        dataTask = URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let error = error {
                ApptentiveLogger.default.error("Error with url for ApptentiveImage: \(error)")
                return
            }
            guard let data = data, let image = UIImage(data: data) else {
                ApptentiveLogger.default.error("Error with data for ApptentiveImage: \(error)")
                return
            }
            DispatchQueue.main.async {
                self.image = image
            }
        }
        dataTask?.resume()
    }

    private func cancelTask() {
        dataTask?.cancel()
    }

}
