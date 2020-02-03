//
//  ImageCache.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import UIKit

/**
 Responsible for downloading and caching image resources.
 */
class ImageCache {

    static let `default` = ImageCache()

    var images: [URL: UIImage] = [:]
    var inProgress: [URL] = []

    let networkClient: NetworkClientProtocol

    /**
     */
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }

    /**
     If the image is already on cache, the completion handler is executed immediately (frim the client's point
     of view, it looks as if "it took 0 ms to download").
     */
    func fetchImage(at url: URL, completion: @escaping ((UIImage?) -> Void)) {
        if inProgress.contains(url) {
            // (avoid duplicate requests)
            return
        }
        if inProgress.count > 10 {
            // (limit bandwidth)
            return
        }

        if let cached = images[url] {
            return completion(cached)
        }

        networkClient.getData(at: url, completion: { [weak self] (data) in
            if let image = UIImage(data: data) {
                self?.images[url] = image
                completion(image)
            } else {
                completion(nil)
            }
            self?.inProgress.removeAll(where: { $0 == url })

        }, failure: {(_) in
            // TODO: handle
        })
    }
}
