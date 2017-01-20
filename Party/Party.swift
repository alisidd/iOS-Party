//
//  Party.swift
//  Party
//
//  Created by Matthew on 2016-11-14.
//  Copyright © 2016 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class Party: NSObject {
    var partyName = String()
    var genres = [String]()
    var musicService = MusicService.appleMusic
    
    var numPeople = 0
    var password: String?
    var isLocked = false
}
