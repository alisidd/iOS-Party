//
//  Automation.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/5/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

//Code taken from https://stackoverflow.com/questions/28076020/ios-different-font-sizes-within-single-size-class-for-different-devices
extension UIDevice {
    enum DeviceTypes {
        case iPhone4_4s
        case iPhone5_5s_SE
        case iPhone6_6s
        case iPhone6p_6ps
        case iPhoneX
        case after_iPhoneX
    }
    
    static var deviceType : DeviceTypes {
        switch UIScreen.main.bounds.height {
        case 480.0:
            return .iPhone4_4s
        case 568.0:
            return .iPhone5_5s_SE
        case 667.0:
            return .iPhone6_6s
        case 736.0:
            return .iPhone6p_6ps
        case 812.0:
            return .iPhoneX
        default:
            return .after_iPhoneX
        }
    }
}

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
                                                range: NSMakeRange(0, deviceName.count))
            let rangeNotFound = NSMakeRange(NSNotFound, 0)
            
            var nameParts = [String]()
            for result in matches {
                for i in 1..<result.numberOfRanges {
                    if !NSEqualRanges(result.range(at: i), rangeNotFound) {
                        nameParts.append((deviceName as NSString).substring(with: result.range(at: i)).capitalized)
                    }
                }
            }
            
            if nameParts.count > 0 {
                username = nameParts.joined(separator: " ")
            }
        }
        catch { print("[Error] While searching for username from device name") }
        
        return username
    }
    
}

extension String {
    var replacedWhiteSpaceForURL: String {
        return components(separatedBy: " ").filter { !$0.isEmpty }.joined(separator: "+")
    }
}
