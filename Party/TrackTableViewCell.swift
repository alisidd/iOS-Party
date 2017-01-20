//
//  TrackTableViewCell.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class TrackTableViewCell: UITableViewCell {
    
    @IBOutlet weak var albumArt: UIImageView! {
        didSet {
            let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
            
            let blurView = UIVisualEffectView(effect: blurEffect)
            blurView.frame = albumArt.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            albumArt.addSubview(blurView)
        }
    }
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
