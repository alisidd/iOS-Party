//
//  CurrentlyPlayingTrackTableViewCell.swift
//  Party
//
//  Created by Ali Siddiqui on 1/20/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class CurrentlyPlayingTrackTableViewCell: UITableViewCell {
    
    @IBOutlet weak var artwork: UIImageView! {
        didSet {
            let blurEffect: UIBlurEffect = UIBlurEffect(style: .dark)
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.alpha = 0.6
            blurView.frame = artwork.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            artwork.addSubview(blurView)
        }
    }
    @IBOutlet weak var playPauseButton: UIButton! {
        didSet {
            playPauseButton.alpha = 0.6
        }
    }
    @IBOutlet weak var nextButton: UIButton! {
        didSet {
            nextButton.alpha = 0.6
        }
    }
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artistName: UILabel!
}
