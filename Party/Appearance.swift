//
//  Appearance.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/26/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

extension UIView {
    func makeBorder() {
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1, green: 166/255, blue: 35/255, alpha: 1).cgColor
        layer.cornerRadius = 30
    }
    
    func removeBorder() {
        layer.borderWidth = 0
    }
}
