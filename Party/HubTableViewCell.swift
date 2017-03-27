//
//  HubTableViewCell.swift
//  WeJ
//
//  Created by Ali Siddiqui on 3/21/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class HubTableViewCell: UITableViewCell {
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        DispatchQueue.main.async {
            if highlighted {
                self.textLabel?.textColor = UIColor(red: 246/255, green: 166/255, blue: 35/255, alpha: 1)
            } else {
                self.textLabel?.textColor = .white
            }
        }
    }
}
