//
//  partyNameTextField.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/5/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class partyNameTextField: UITextField {
    let orange = UIColor(red: 1, green: 166/255, blue: 35/255, alpha: 1)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customizeTextField()
    }
    
    func customizeTextField() {
        tintColor = orange
        autocapitalizationType = .words
        returnKeyType = .done
        addBottomBorder()
    }
    
    func addBottomBorder() {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: frame.height + 10, width: frame.width, height: 2)
        bottomLine.backgroundColor = orange.cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
}
