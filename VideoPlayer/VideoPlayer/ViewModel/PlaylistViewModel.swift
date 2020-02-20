//
//  PlaylistViewModel.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation

/**
 View model for the initial screen.
 */
class PlaylistViewModel {

    private var items: [PlaylistItemViewModel] = []

    // MARK: - Initialization

    init(items: [PlaylistItemViewModel]) {
        self.items = items
    }

    func fetchData(completion: @escaping (() -> Void), failure: @escaping ((Error) -> Void)) {
        ListCache.default.fetchList(completion: { [weak self] in

            let model = ListCache.default.cache
            self?.items = model.map {
                // (duration is in ms)
                let seconds = Int($0.duration/1000)

                /*
                 For demo purposes, and to avoid the need of a server), load the
                 local thumbnail and movie instead of those specified in the
                 item's URLs:
                 */
                return PlaylistItemViewModel(
                    title: $0.title,
                    subtitle: $0.presenterName,
                    formattedDuration: String(seconds: seconds, showHours: (seconds > 3600)),
                    thumbnailURL: Bundle.main.url(forResource: "Sample", withExtension: "png")!,
                    videoURL: Bundle.main.url(forResource: "Sample", withExtension: "mov")!)
            }
            completion()

        }, failure: failure)
    }

    // MARK: - Data Source

    var numberOfSections: Int {
        return 1
    }

    func numberOfItems(inSection index: Int) -> Int {
        return items.count
    }

    func item(at indexPath: IndexPath) -> PlaylistItemViewModel {
        return items[indexPath.row]
    }

    func playerViewModelForItem(at indexPath: IndexPath) -> PlayerViewModel {
        let item = items[indexPath.row]
        let url = item.videoURL
        let videoItem = VideoItem(url: url)
        return PlayerViewModel(videoItem: videoItem, readyHandler: {})
    }
}

// MARK: - Supporting Types

struct PlaylistItemViewModel {
    let title: String
    let subtitle: String
    let formattedDuration: String
    let thumbnailURL: URL
    let videoURL: URL
}
