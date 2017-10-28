//
//  HubTableViewCell.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 3/21/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class HubTableViewCell: UITableViewCell {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var hubLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            hubLabel.changeToSmallerFont()
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        DispatchQueue.main.async {
            if highlighted {
                if self.hubLabel.text == NSLocalizedString("View Lyrics", comment: "") {
                    self.iconView.image = #imageLiteral(resourceName: "lyricsIconHighlighted")
                } else {
                    self.iconView.image = #imageLiteral(resourceName: "leavePartyIconHighlighted")
                }
                
                self.hubLabel.textColor = AppConstants.orange
            } else {
                if self.hubLabel.text == NSLocalizedString("View Lyrics", comment: "") {
                    self.iconView.image = #imageLiteral(resourceName: "lyricsIcon")
                } else {
                    self.iconView.image = #imageLiteral(resourceName: "leavePartyIcon")
                }
                
                self.hubLabel.textColor = .white
            }
        }
    }
    
}
