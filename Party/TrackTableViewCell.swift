//
//  TrackTableViewCell.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
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
    
    @IBOutlet weak var albumArt: UIImageView! {
        didSet {
            let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
            
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.alpha = 0.9
            blurView.frame = albumArt.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            albumArt.addSubview(blurView)
            albumArt.contentMode = .scaleAspectFill
        }
    }
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    
    private var isAdded = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    @IBAction func addTrack(_ sender: UIButton) {
        sender.fadeTransition(duration: 0.4)
        if isAdded {
            sender.setTitle("+", for: .normal)
            isAdded = false
        } else {
            sender.setTitle("✓", for: .normal)
            isAdded = true
        }
        
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
