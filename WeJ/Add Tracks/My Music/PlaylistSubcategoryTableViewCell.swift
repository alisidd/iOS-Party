//
//  PlaylistSubcategoryTableViewCell.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/11/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class PlaylistSubcategoryTableViewCell: UITableViewCell {

    @IBOutlet weak var optionLabel: UILabel!
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        DispatchQueue.main.async {
            if highlighted {
                self.optionLabel.textColor = AppConstants.orange
            } else {
                self.optionLabel.textColor = .white
            }
        }
    }
}
