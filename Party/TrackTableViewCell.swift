//
//  TrackTableViewCell.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

extension UIView {
    func fadeTransition(duration:CFTimeInterval) {
        let animation:CATransition = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name:
            kCAMediaTimingFunctionEaseInEaseOut)
        animation.type = kCATransitionFade
        animation.duration = duration
        self.layer.add(animation, forKey: kCATransitionFade)
    }
}

import UIKit

class TrackTableViewCell: UITableViewCell {
    
    // MARK: - General Variables
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    
    /*
    var track = Track()
    
    private var isAdded: Bool {
        if addButton.titleLabel!.text == "✓" {
            return true
        } else {
            return false
        }
    }
    weak var delegate: ModifyTracksQueueDelegate?
    
    // MARK: - Functions

    @IBAction func addTrack(_ sender: UIButton) {
        sender.fadeTransition(duration: 0.3)
        if isAdded {
            sender.setTitle("+", for: .normal)
            self.delegate?.removeFromQueue(track: track)
        } else {
            sender.setTitle("✓", for: .normal)
            track.artwork = artworkImageView.image
            self.delegate?.addToQueue(track: track)
        }
    }*/
}
