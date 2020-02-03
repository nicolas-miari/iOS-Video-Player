//
//  PlayerViewController.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/23.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import UIKit
import AVKit

/**
 Custom video player view controller that mimics the appearance of AVPlayerViewController for the most part,
 but its view supports animated transitions for e.g. presenting full-screen from a thumbnail.
 */
class PlayerViewController: UIViewController {

    // MARK: - GUI

    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var slider: VideoSlider!
    @IBOutlet weak var elapsedTimeLabel:UILabel!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var rewButton: UIButton!
    @IBOutlet weak var ffButton: UIButton!

    // TEST

    private var landscapeConstraints: [NSLayoutConstraint] = []
    private var portraitConstraints: [NSLayoutConstraint] = []

    // MARK: - Configuration

    var player: AVPlayer! {
        didSet {
            if let duration = player.currentItem?.asset.duration {
                self.durationInSeconds = duration.seconds
            }
        }
    }

    var sourceFrame: CGRect = .zero

    // MARK: - Internal State

    /// Flag to prevet overlapping animations for showing/hiding the controls box
    fileprivate var animatingToggleControlView = false

    /// CoreAnimation layer that actually renders the video content.
    fileprivate var videoLayer: AVPlayerLayer!

    /// Cached duration of the video asset in seconds, for updating labels during playback/seeking.
    fileprivate var durationInSeconds: Double = 0

    /// One-second timer used for periodically updating the progress slider and timestamp labels while
    /// the video plays.
    fileprivate var refreshTimer: Timer!

    // MARK: - UIViewController

    override var modalPresentationStyle: UIModalPresentationStyle {
        set { }
        get { return .fullScreen }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        view.clipsToBounds = true

        slider.setThumbImage(UIImage(named: "Knob"), for: .normal)
        slider.setThumbImage(UIImage(named: "Knob"), for: .highlighted)

        controlsView.alpha = 0.0

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapHandler(_:)))
        view.addGestureRecognizer(recognizer)

        self.videoLayer = AVPlayerLayer()
        videoLayer.videoGravity = .resizeAspect
        view.layer.insertSublayer(videoLayer, at: 0)

        // Determine the maximum frame width of the remaining time label:
        updateLabels()

        // Setup PORTRAIT constraints:
        portraitConstraints.append(slider.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 22))
        portraitConstraints.append(slider.leftAnchor.constraint(equalTo: controlsView.leftAnchor, constant: 16))
        portraitConstraints.append(slider.rightAnchor.constraint(equalTo: controlsView.rightAnchor, constant: -16))
        portraitConstraints.append(elapsedTimeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 16))
        portraitConstraints.append(elapsedTimeLabel.leadingAnchor.constraint(equalTo: slider.leadingAnchor, constant: 0))
        portraitConstraints.append(remainingTimeLabel.topAnchor.constraint(equalTo: elapsedTimeLabel.topAnchor, constant: 0))
        portraitConstraints.append(remainingTimeLabel.trailingAnchor.constraint(equalTo: slider.trailingAnchor, constant: 0))
        portraitConstraints.append(playPauseButton.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 24))
        portraitConstraints.append(playPauseButton.centerXAnchor.constraint(equalTo: slider.centerXAnchor, constant: 0))
        portraitConstraints.append(playPauseButton.bottomAnchor.constraint(equalTo: controlsView.bottomAnchor, constant: -22))

        // Setup SHARED CONSTRAINTS (always active)
        rewButton.rightAnchor.constraint(equalTo: playPauseButton.leftAnchor, constant: -36).isActive = true
        rewButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor, constant: 0).isActive = true

        ffButton.leftAnchor.constraint(equalTo: playPauseButton.rightAnchor, constant: 36).isActive = true
        ffButton.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor, constant: 0).isActive = true

        // Setup LANDSCAPE constraints:
        landscapeConstraints.append(rewButton.leftAnchor.constraint(equalTo: controlsView.leftAnchor, constant: 12))
        landscapeConstraints.append(playPauseButton.topAnchor.constraint(equalTo: controlsView.topAnchor, constant: 12))
        landscapeConstraints.append(playPauseButton.bottomAnchor.constraint(equalTo: controlsView.bottomAnchor, constant: -12))
        landscapeConstraints.append(elapsedTimeLabel.leftAnchor.constraint(equalTo: ffButton.rightAnchor, constant: 24))
        landscapeConstraints.append(elapsedTimeLabel.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor, constant: 0))
        landscapeConstraints.append(slider.leftAnchor.constraint(equalTo: elapsedTimeLabel.leftAnchor, constant: 18 + elapsedTimeLabel.frame.width))
        landscapeConstraints.append(slider.centerYAnchor.constraint(equalTo: playPauseButton.centerYAnchor, constant: 0))
        landscapeConstraints.append(slider.rightAnchor.constraint(equalTo: controlsView.rightAnchor, constant: -28 - remainingTimeLabel.frame.width))
        landscapeConstraints.append(remainingTimeLabel.topAnchor.constraint(equalTo: elapsedTimeLabel.topAnchor, constant: 0))
        landscapeConstraints.append(remainingTimeLabel.rightAnchor.constraint(equalTo: controlsView.rightAnchor, constant: -12))
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        videoLayer.frame = view.bounds

        let visualEffectsView = controlsView!
        visualEffectsView.layer.masksToBounds = true

        // Refresh toolbox mask (rounded corners):
        let path = UIBezierPath.superellipse(in: visualEffectsView.bounds, cornerRadius: 150)
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        visualEffectsView.layer.mask = mask
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateControlContraints(for: size, duration: coordinator.transitionDuration)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateControlContraints(for: view.frame.size, duration: 0, completion: { [weak self] in
            self?.toggleControlVisibility()
        })

        videoLayer.player = player
        self.isPlaying = true

        self.refreshTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerFired), userInfo: nil, repeats: true)
    }

    // MARK: - Programmatic Operation

    private (set) var isPlaying: Bool {
        set {
            if newValue {
                player.rate = 1.0
                playPauseButton?.setImage(UIImage(named: "Pause"), for: .normal)
            } else {
                player.rate = 0.0
                playPauseButton?.setImage(UIImage(named: "Play"), for: .normal)
            }
            player.rate = newValue ? 1.0 : 0.0
        }
        get {
            return (player.rate == 1.0)
        }
    }

    func play() {
        self.isPlaying = true
    }

    func pause() {
        self.isPlaying = false
    }

    // MARK: - Control Actions

    @IBAction func done(_ sender: Any) {

        refreshTimer.invalidate()

        hideControls(animated: false, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        let elapsedSeconds = durationInSeconds * Double(sender.value)
        let time = CMTime(seconds: elapsedSeconds, preferredTimescale: 1)
        player.seek(to: time, completionHandler: { (_) in
            self.updateLabels()
        })
    }

    @IBAction func playPause(_ sender: UIButton) {
        isPlaying = !isPlaying
    }

    @IBAction func rewind(_ sender: UIButton) {
        let seconds = player.currentTime().seconds
        let newTime = seconds >= 15 ? seconds - 15 : 0

        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1), completionHandler: { (_) in
            self.updateSlider()
            self.updateLabels()
        })
    }

    @IBAction func fastForward(_ sender: UIButton) {
        let seconds = player.currentTime().seconds
        let newTime = seconds + 15 <= durationInSeconds ? seconds + 15 : durationInSeconds

        player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1), completionHandler: { (_) in
            self.updateSlider()
            self.updateLabels()
        })
    }

    // MARK: - Timer Callbacks

    @objc fileprivate func timerFired() {
        guard isPlaying else {
            return
        }
        // Update slider:
        updateSlider()

        // Update labels:
        updateLabels()
    }

    // MARK: - Gesture Handlers

    @objc fileprivate func tapHandler(_ recognizer: UITapGestureRecognizer) {
        toggleControlVisibility()
    }

    // MARK: - Control Visibility

    fileprivate func toggleControlVisibility() {
        if animatingToggleControlView {
            return
        }
        animatingToggleControlView = true

        if controlsView.alpha == 0.0 {
            showControls(animated: true, completion: {
                self.animatingToggleControlView = false
            })
        } else {
            hideControls(animated: true, completion: {
                self.animatingToggleControlView = false
            })
        }
    }

    fileprivate func showControls(animated: Bool, completion: @escaping (() -> Void)) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.controlsView.alpha = 1

            }, completion: {(_) in
                completion()
            })
        } else {
            self.controlsView.alpha = 1
            completion()
        }
    }

    fileprivate func updateControlContraints(for viewSize: CGSize, duration: Double, completion: (() -> Void)? = nil) {
        if viewSize.width > viewSize.height {
            // Landscape:
            NSLayoutConstraint.deactivate(portraitConstraints)
            NSLayoutConstraint.activate(landscapeConstraints)

        } else {
            // Portrait:
            NSLayoutConstraint.deactivate(landscapeConstraints)
            NSLayoutConstraint.activate(portraitConstraints)
        }

        UIView.animate(withDuration: duration, animations: {
            self.view.layoutIfNeeded()
        }, completion: { (_) in
            completion?()
        })
    }

    fileprivate func hideControls(animated: Bool , completion: @escaping (() -> Void)) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.controlsView.alpha = 0

            }, completion: {(_) in
                completion()
            })
        } else {
            self.controlsView.alpha = 0
            completion()
        }
    }

    // MARK: - UI Refresh

    private func updateLabels() {
        let elapsedSeconds = player.currentTime().seconds
        let remainingSeconds = durationInSeconds - elapsedSeconds

        let showHours = durationInSeconds > 3600

        elapsedTimeLabel.text = String(seconds: Int(elapsedSeconds), showHours: showHours)
        remainingTimeLabel.text = "-" + String(seconds: Int(remainingSeconds), showHours: showHours)
    }

    private func updateSlider() {
        let elapsedSeconds = player.currentTime().seconds
        let ratio = elapsedSeconds / durationInSeconds
        slider.value = Float(ratio)
    }
}
