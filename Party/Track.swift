//
//  Song.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

class Track: NSObject {
    var id = String()
    var name = String()
    var artist = String()
    
    var lowResArtworkURL = String()
    var artwork: UIImage?
    
    var mediumResArtworkURL: String?
    var mediumResArtwork: UIImage?
    
    var highResArtworkURL = String()
    var highResArtwork: UIImage?
    
    var length: TimeInterval?
}
