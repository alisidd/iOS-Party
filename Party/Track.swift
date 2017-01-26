//
//  Song.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation
import UIKit

class Track: NSObject {
    var id = String()
    var name = String()
    var artist = String()
    var album = String()
    
    var lowResArtworkURL = String()
    var highResArtworkURL = String()
    var artwork: UIImage?
    
    var danceability: Int?
}
