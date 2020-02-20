//
//  AVPlayer+Extensions.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/02/21.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import AVFoundation

extension AVPlayer {

    var isAtEnd: Bool {
        guard let item = currentItem else {
            return false
        }
        let duration = item.duration
        guard !CMTIME_IS_INDEFINITE(duration) else {
            return false
        }
        return (item.currentTime() >= duration)
    }

    var isPlaying: Bool {
        return (rate > 0.0)
    }

    func play() {
        self.rate = 1.0
    }

    func stop() {
        self.rate = 0.0
    }

    func replay() {
        seek(to: .zero) { (_) in
            self.rate = 1.0
        }
    }
}
