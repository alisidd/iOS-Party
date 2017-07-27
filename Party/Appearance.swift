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

extension UIImage {
    func addGradient() -> UIImage {
        UIGraphicsBeginImageContext(self.size)
        let context = UIGraphicsGetCurrentContext()
        
        self.draw(at: CGPoint(x: 0, y: 0))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let locations: [CGFloat] = [0.0, 1.0]
        
        let bottom = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1).cgColor
        let top = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2).cgColor
        
        let colors = [top, bottom] as CFArray
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations)
        
        let startPoint = CGPoint(x: self.size.width/2, y: 0)
        let endPoint = CGPoint(x: self.size.width/2, y: self.size.height)
        
        context!.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: UInt32(0)))
        
        let imageToReturn = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return imageToReturn!
    }
}
