//
//  PlaylistSelectionViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/10/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import RKNotificationHub

class PlaylistSelectionViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    private var badge: RKNotificationHub!
    private var totalTracksCount: Int {
        let controller = tabBarController! as! AddTracksTabBarController
        return controller.tracksSelected.count + controller.libraryTracksSelected.count
    }
    
    var musicService: MusicService!
    
    @IBOutlet weak var albumsImageView: UIImageView!
    @IBOutlet weak var albumsButton: UIButton!
    
    @IBOutlet weak var artistsStackView: UIStackView!
    @IBOutlet weak var artistsImageView: UIImageView!
    @IBOutlet weak var artistsButton: UIButton!
    
    @IBOutlet weak var playlistsImageView: UIImageView!
    @IBOutlet weak var playlistsButton: UIButton!
    
    @IBOutlet weak var allSongsImageView: UIImageView!
    @IBOutlet weak var allSongsButton: UIButton!
    
    var stackMapper: [UIButton: UIImageView] {
        return [
            albumsButton: albumsImageView,
            artistsButton: artistsImageView,
            playlistsButton: playlistsImageView,
            allSongsButton: allSongsImageView
        ]
    }
    
    func setBadge(to count: Int) {
        badge.count = Int32(count)
        badge.pop()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initializeBadge()
        adjustViews()
        adjustFontSizes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setBadge(to: totalTracksCount)
    }
    
    private func initializeBadge() {
        badge = RKNotificationHub(view: doneButton.titleLabel, andCount: Int32(totalTracksCount))
        badge.moveCircleBy(x: 51, y: 0)
        badge.scaleCircleSize(by: 0.7)
        badge.setCircleColor(AppConstants.orange, label: .white)
    }
    
    private func adjustViews() {
        titleLabel.text = musicService.toString()
        if musicService == .spotify {
            artistsStackView.isHidden = true
        }
        [albumsButton, artistsButton, playlistsButton, allSongsButton].forEach { button in
            button?.addTarget(self, action:#selector(highlightIcon(sender:)), for: .touchDown)
            button?.addTarget(self, action:#selector(unhighlightIcon(sender:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
        }
        
        
    }
    
    @objc private func highlightIcon(sender: UIButton) {
        stackMapper[sender]?.isHighlighted = true
    }
    
    @objc private func unhighlightIcon(sender: UIButton) {
        stackMapper[sender]?.isHighlighted = false
    }
    
    private func adjustFontSizes() {
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            titleLabel.changeToSmallerFont()
            doneButton.changeToSmallerFont()
            albumsButton.changeToSmallerFont()
            artistsButton.changeToSmallerFont()
            playlistsButton.changeToSmallerFont()
            allSongsButton.changeToSmallerFont()
        }
    }

    // MARK: - Navigation
    
    @IBAction func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlaylistSubcategorySelectionViewController {
            switch segue.identifier! {
            case "Show Albums": controller.playlistType = .albums
            case "Show Artists": controller.playlistType = .artists
            case "Show Playlists": controller.playlistType = .playlists
            default: break
            }
            controller.musicService = musicService
        } else if let controller = segue.destination as? LibraryTracksViewController {
            controller.musicService = musicService
            controller.playlistType = .all
            controller.playlistName = NSLocalizedString("All Songs", comment: "")
        }
    }

}
