//
//  searchTextField.swift
//  Party
//
//  Created by Ali Siddiqui on 3/15/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class searchTextField: UITextField {
    
    let searchIconView = UIImageView(frame: CGRect(x: 0, y: 0, width: 17, height: 17))
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customizeTextField()
    }
    
    func customizeTextField() {
        attributedPlaceholder = NSAttributedString(string: "Search", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        
        autocapitalizationType = UITextAutocapitalizationType.sentences
        returnKeyType = .search
        addBottomBorder()
        addSearchIcon()
    }
    
    func addBottomBorder() {
        let bottomLine = CALayer()
        bottomLine.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
        bottomLine.backgroundColor = UIColor(red: 1, green: 166/255, blue: 35/255, alpha: 1).cgColor
        borderStyle = .none
        layer.addSublayer(bottomLine)
    }
    
    func addSearchIcon() {
        leftViewMode = .always
        
        searchIconView.image = #imageLiteral(resourceName: "searchIcon")
        leftView = searchIconView
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: searchIconView.frame.maxX + 10, y: bounds.origin.y, width: bounds.width, height: bounds.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: searchIconView.frame.maxX + 10, y: bounds.origin.y, width: bounds.width, height: bounds.height)
    }
}
