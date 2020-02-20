//
//  Player.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/02/20.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import AVFoundation

final class Player {

    let videoLayer: CALayer

    var timeHandler: ((Double) -> Void)?

    var completeHandler: (() -> Void)?

    // MARK: -

    private let player: AVPlayer

    private var duration: CMTime = .zero

    private var timeObserver: Any?

    private var readyObserver: NSKeyValueObservation?

    private let readyHandler: (() -> Void)

    // MARK: - Initialization

    init(video: VideoItem, readyHandler: @escaping (() -> Void)) {
        let playerItem = AVPlayerItem(asset: video.asset)
        let player = AVPlayer(playerItem: playerItem)
        let layer =  AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect

        self.player = player
        self.videoLayer = layer
        self.readyHandler = readyHandler

        NotificationCenter.default.addObserver(self, selector: #selector(previewDidPlayToEnd(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }

    func prepareToPlay() {
        self.readyObserver = player.currentItem!.observe(\.status, options: [.new, .old], changeHandler: { (item, change) in
            self.readyObserver?.invalidate()
            self.isReady = (item.status == .readyToPlay)
            self.duration = item.duration
            self.readyHandler()
        })
    }

    var isReady: Bool = false

    // MARK: - Operation

    var isPlaying: Bool {
        return player.isPlaying
    }

    func play() {
        if let handler = timeHandler {
            self.timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1.0/10.0, preferredTimescale: 30), queue: .main, using: { (time) in
                handler(time.seconds)
            })
        }

        // Did we play to the end?
        if player.isAtEnd {
            player.replay()
        } else {
            player.play()
        }
    }

    func pause() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            self.timeObserver = nil
        }
        player.stop()
    }

    func seek(to time: Double, completion: @escaping (() -> Void)) {
        let time = CMTime(seconds: time, preferredTimescale: 600)
        let tolerance = CMTime(seconds: 1.0/30.0, preferredTimescale: CMTimeScale(600))

        player.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance, completionHandler: {(_) in
            completion()
        })
    }

    var totalDuration: Double {
        return player.currentItem?.duration.seconds ?? 0
    }

    var currentTime: Double {
        let seconds = player.currentTime().seconds
        return ((seconds >= 0.0) ? seconds : 0.0)
    }

    // MARK: - Notification Handlers

    @objc func previewDidPlayToEnd(_ notification: Notification) {
        completeHandler?()
    }
}
