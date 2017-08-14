//
//  PlaylistSelectionViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/10/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import BadgeSwift

class PlaylistSelectionViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var badge: BadgeSwift!
    
    var musicService: MusicService!
    @IBOutlet weak var artistsButton: UIButton!
    
    func setBadge(to count: Int) {
        badge.isHidden = count == 0
        badge.text = String(count)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        adjustViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeBadge()
    }
    
    private func initializeBadge() {
        let controller = tabBarController! as! AddTracksTabBarController
        setBadge(to: controller.tracksSelected.count + controller.libraryTracksSelected.count)
    }
    
    private func adjustViews() {
        titleLabel.text = musicService.toString()
        if musicService == .spotify {
            artistsButton.isHidden = true
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
        } else if let controller = segue.destination as? UserTracksViewController {
            controller.musicService = musicService
            controller.playlistType = .all
            controller.playlistName = "All Songs"
        }
    }

}
