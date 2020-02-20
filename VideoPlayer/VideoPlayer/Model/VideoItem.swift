//
//  VideoItem.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/02/20.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import AVFoundation

final class VideoItem {

    let asset: AVAsset

    init(url: URL) {
        self.asset = AVAsset(url: url)
    }

    init(asset: AVAsset) {
        self.asset = asset
    }
}
