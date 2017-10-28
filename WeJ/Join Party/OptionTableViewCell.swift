//
//  OptionTableViewCell.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/25/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class OptionTableViewCell: UITableViewCell {

    @IBOutlet weak var optionName: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            optionName.changeToSmallerFont()
        }
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            optionName.textColor = AppConstants.orange
        } else {
            optionName.textColor = .white
        }
    }
    
}
