//
//  partyNameTextField.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/5/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class partyNameTextField: UITextField {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customizeTextField()
    }
    
    func customizeTextField() {
        tintColor = AppConstants.orange
        autocapitalizationType = .words
        returnKeyType = .done
        addBottomBorder()
    }
    
    func addBottomBorder() {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: frame.height + 10, width: frame.width, height: 1)
        bottomLine.backgroundColor = AppConstants.orange.cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
    
}
