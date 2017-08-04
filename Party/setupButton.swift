//
//  setupButton.swift
//  Party
//
//  Created by Mohammad Ali Siddiqui and Matthew Paletta on 11/9/16.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import UIKit

class setupButton: UIButton {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        if state == .selected {
            super.setTitleColor(UIColor(red: 1, green: 166/255, blue: 35/255, alpha: 1), for: state)
        } else {
            super.setTitleColor(UIColor.white, for: state)
        }
    }
}
