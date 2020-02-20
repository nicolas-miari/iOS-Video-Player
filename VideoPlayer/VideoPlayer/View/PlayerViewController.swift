//
//  PlayerViewController.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/23.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import UIKit

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

    var viewModel: PlayerViewModel! {
        didSet {
            viewModel?.playbackProgressHandler = {[unowned self] (time) in
                guard self.isPlaying else { return }
                self.updateSlider(time: time)
                self.updateLabels(time: time)
            }
            viewModel.playbackCompletionHandler = {[unowned self] in
                self.isPlaying = false
                //self.updateSlider(time: 0)
                //self.updateLabels(time: 0)
            }
        }
    }

    var sourceFrame: CGRect = .zero

    // MARK: - Internal State

    /// Flag to prevet overlapping animations for showing/hiding the controls box
    fileprivate var animatingToggleControlView = false

    /// CoreAnimation layer that actually renders the video content.
    fileprivate var videoLayer: CALayer!

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

        self.videoLayer = viewModel.videoLayer
        view.layer.insertSublayer(videoLayer, at: 0)
        videoLayer.isHidden = true

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateControlContraints(for: size, duration: coordinator.transitionDuration)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        updateControlContraints(for: view.frame.size, duration: 0, completion: { [weak self] in
            self?.toggleControlVisibility()
        })

        /*
         Do not update labels until video starts playing. Video duration cannot be reliably
         queried until the underlying player item is in the 'ready' state.
         */
        videoLayer.isHidden = false
        self.isPlaying = true
    }

    // MARK: - Programmatic Operation

    private (set) var isPlaying: Bool {
        set {
            if newValue {
                viewModel.play()
                playPauseButton?.setImage(UIImage(named: "Pause"), for: .normal)
            } else {
                viewModel.pause()
                playPauseButton?.setImage(UIImage(named: "Play"), for: .normal)
            }
        }
        get {
            return viewModel.isPlaying
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
        self.isPlaying = false
        hideControls(animated: false, completion: {
            self.dismiss(animated: true, completion: nil)
        })
    }

    @IBAction func sliderValueChanged(_ sender: UISlider) {
        self.isPlaying = false
        let elapsedSeconds = viewModel.totalDuration * Double(sender.value)
        viewModel.seek(to: elapsedSeconds) {
            self.updateLabels(time: elapsedSeconds)
        }
    }

    @IBAction func playPause(_ sender: UIButton) {
        isPlaying = !isPlaying
    }

    @IBAction func rewind(_ sender: UIButton) {
        let seconds = viewModel.currentTime
        let newTime = seconds >= 15 ? seconds - 15 : 0
        viewModel.seek(to: newTime) {
            self.updateSlider(time: newTime)
            self.updateLabels(time: newTime)
        }
    }

    @IBAction func fastForward(_ sender: UIButton) {
        let seconds = viewModel.currentTime
        let total = viewModel.totalDuration
        let newTime = seconds + 15 <= total ? seconds + 15 : total
        viewModel.seek(to: newTime) {
            self.updateSlider(time: newTime)
            self.updateLabels(time: newTime)
        }
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

    private func updateLabels(time: Double) {
        let remainingSeconds = viewModel.totalDuration - time
        let showHours = viewModel.totalDuration > 3600
        elapsedTimeLabel.text = String(seconds: Int(time), showHours: showHours)
        remainingTimeLabel.text = "-" + String(seconds: Int(remainingSeconds), showHours: showHours)
    }

    private func updateSlider(time: Double) {
        let ratio = time / viewModel.totalDuration
        slider.value = Float(ratio)
    }
}
