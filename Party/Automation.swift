//
//  Automation.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/5/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

//Code taken from https://stackoverflow.com/questions/8261961/better-way-to-get-the-users-name-from-device
extension UIDevice {
    func userName() -> String {
        let deviceName = self.name
        let expression = "^(?:iPhone|phone|iPad|iPod)\\s+(?:de\\s+)?(?:[1-9]?S?\\s+)?|(\\S+?)(?:['']?s)?(?:\\s+(?:iPhone|phone|iPad|iPod)\\s+(?:[1-9]?S?\\s+)?)?$|(\\S+?)(?:['']?的)?(?:\\s*(?:iPhone|phone|iPad|iPod))?$|(\\S+)\\s+"
        
        var username = deviceName
        
        do {
            let regex = try NSRegularExpression(pattern: expression, options: .caseInsensitive)
            let matches = regex.matches(in: deviceName as String,
                                                options: NSRegularExpression.MatchingOptions.init(rawValue: 0),
                                                range: NSMakeRange(0, deviceName.characters.count))
            let rangeNotFound = NSMakeRange(NSNotFound, 0)
            
            var nameParts = [String]()
            for result in matches {
                for i in 1..<result.numberOfRanges {
                    if !NSEqualRanges(result.rangeAt(i), rangeNotFound) {
                        nameParts.append((deviceName as NSString).substring(with: result.rangeAt(i)).capitalized)
                    }
                }
            }
            
            if nameParts.count > 0 {
                username = nameParts.joined(separator: " ")
            }
        }
        catch { NSLog("[Error] While searching for username from device name") }
        
        return username
    }
}
