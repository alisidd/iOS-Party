//
//  Song.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import Foundation

class Track: NSObject {
    var id = String()
    var name = String()
    var artist = String()
    var album = String()
    
    var lowResArtworkURL = String()
    var artwork: UIImage?
    
    var highResArtworkURL = String()
    var highResArtwork: UIImage?
    
    var length: TimeInterval?
    var danceability: Int?
}
