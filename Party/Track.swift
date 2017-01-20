//
//  Song.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

class Track: NSObject {
    var id = 0
    var name = String()
    var artist = String()
    var album = String()
    var artworkURL = String()
    
    var danceability: Int?
}
