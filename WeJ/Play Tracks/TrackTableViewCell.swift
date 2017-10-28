//
//  TrackTableViewCell.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

class TrackTableViewCell: UITableViewCell {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var trackName: UILabel!
    @IBOutlet weak var artistName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        artworkImageView.layer.cornerRadius = 10
        artworkImageView.clipsToBounds = true
        
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            trackName.changeToSmallerFont()
            artistName.changeToSmallerFont()
        }
    }
    
}
