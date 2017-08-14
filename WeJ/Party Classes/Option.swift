//
//  Option.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/14/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

class Option {
    
    var name: String
    var tracks: [Track]
    
    init(name: String, tracks: [Track]) {
        self.name = name
        self.tracks = tracks
    }
    
}
