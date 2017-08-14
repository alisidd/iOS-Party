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
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        DispatchQueue.main.async {
            if highlighted {
                self.hubLabel.textColor = AppConstants.orange
            } else {
                self.hubLabel.textColor = .white
            }
        }
    }
    
}
