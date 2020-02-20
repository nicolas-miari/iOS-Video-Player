//
//  PlayerViewModel.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/02/20.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import Foundation
import QuartzCore

final class PlayerViewModel {

    let player: Player

    private(set) var isSeeking: Bool = false

    var videoLayer: CALayer {
        return player.videoLayer
    }

    var playbackReadyHandler: (() -> Void)? {
        didSet {
            
        }
    }

    var playbackProgressHandler: ((Double) -> Void)? {
        didSet {
            player.timeHandler = playbackProgressHandler
        }
    }

    var playbackCompletionHandler: (() -> Void)? {
        didSet {
            player.completeHandler = playbackCompletionHandler
        }
    }

    // MARK: - Initalization

    init(videoItem: VideoItem, readyHandler: @escaping (() -> Void)) {
        self.player = Player(video: videoItem, readyHandler: readyHandler)
        player.prepareToPlay()
    }

    // MARK: - Operation

    func seek(to time: Double, completion: @escaping (() -> Void)) {
        /*
         Avoid successive, overlapping seeks:
         (https://developer.apple.com/library/archive/qa/qa1820/_index.html)
         */
        guard !isSeeking else { return }

        player.seek(to: time) { [weak self] in
            self?.isSeeking = false
            completion()
        }
    }

    func play() {
        player.play()
    }

    func pause() {
        player.pause()
    }

    var isPlaying: Bool {
        return player.isPlaying
    }

    var totalDuration: Double {
        return player.totalDuration
    }

    var currentTime: Double {
        return player.currentTime
    }
}
