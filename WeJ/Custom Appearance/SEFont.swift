//
//  SEFont.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/28/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

extension UIButton {
    
    func changeToSmallerFont() {
        titleLabel?.font = titleLabel!.font.withSize(titleLabel!.font.pointSize - 2)
    }
    
}

extension UILabel {
    
    static var smallerTitleFontSize: CGFloat {
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            return 6
        } else {
            return 4
        }
    }
    
    func changeToSmallerFont() {
        font = font.withSize(font.pointSize - 2)
    }
    
}

extension UITextField {
    
    func changeToSmallerFont() {
        font = font?.withSize(font!.pointSize - 2)
    }
    
}

