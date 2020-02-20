//
//  PlaylistViewController.swift
//  VideoPlayer
//
//  Created by Nicolás Miari on 2020/01/22.
//  Copyright © 2020 Nicolás Miari. All rights reserved.
//

import UIKit
import AVKit

/**
 Initial screen (user browses all available videos).
 */
class PlaylistViewController: UITableViewController {

    let viewModel = PlaylistViewModel(items: [])

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()

        if let presented = presentedViewController as? PlayerViewController, let indexPath = tableView.indexPathForSelectedRow {
            let newFrame = self.sourceRectForThumbnail(at: indexPath)
            presented.sourceFrame = newFrame
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        viewModel.fetchData(completion: { [weak self] in

            self?.tableView.reloadData()

        }, failure: { [weak self] (error) in
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

            self?.present(alert, animated: true, completion: nil)
        })

        if let selected = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selected, animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - UITAbleView Delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //tableView.deselectRow(at: indexPath, animated: true)

        playVideo(at: indexPath)
    }

    // MARK: - UITAbleView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems(inSection: section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PlaylistViewCell", for: indexPath) as? PlaylistViewCell else {
            fatalError("Storyboard Inconsistency")
        }
        cell.viewModel = viewModel.item(at: indexPath)
        return cell
    }

    // MARK: - Support

    private func sourceRectForThumbnail(at indexPath: IndexPath) -> CGRect {
        guard let cell = tableView.cellForRow(at: indexPath) as? PlaylistViewCell else {
            fatalError()
        }
        guard let thumbnailFrame = cell.thumbnailImageView?.frame else {
            fatalError()
        }
        guard let window = UIApplication.shared.delegate?.window! else {
            fatalError()
        }
        return window.convert(thumbnailFrame, from: cell.contentView)
    }

    private func playVideo(at indexPath: IndexPath) {
        guard let playerController = UIStoryboard(name: "Player", bundle: nil).instantiateInitialViewController() as? PlayerViewController else {
            fatalError("!!")
        }
        let sourceRect = sourceRectForThumbnail(at: indexPath)

        playerController.viewModel = viewModel.playerViewModelForItem(at: indexPath)
        playerController.transitioningDelegate = FullscreenTransitionDelegate.default
        playerController.sourceFrame = sourceRect
        
        navigationController?.present(playerController, animated: true)
    }
}

// MARK: - Custom Cells

class PlaylistViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var durationLabel: UILabel?
    @IBOutlet weak var thumbnailImageView: UIImageView?

    var viewModel: PlaylistItemViewModel? {
        didSet {
            refresh()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel?.highlightedTextColor = .white
        subtitleLabel?.highlightedTextColor = .white

        let bgColorView = UIView()
        bgColorView.backgroundColor = UIColor(named: "CustomTint")
        selectedBackgroundView = bgColorView
    }

    private func refresh() {
        titleLabel?.text = viewModel?.title
        subtitleLabel?.text = viewModel?.subtitle

        durationLabel?.text = viewModel?.formattedDuration

        guard let url = viewModel?.thumbnailURL else {
            thumbnailImageView?.image = nil
            return
        }
        ImageCache.default.fetchImage(at: url) { [weak self] (image) in
            guard url == self?.viewModel?.thumbnailURL else {
                // Too late, we are displaying a different video now:
                return
            }
            self?.thumbnailImageView?.image = image
        }
    }
}
