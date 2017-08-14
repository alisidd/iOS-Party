//
//  MusicService.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 3/30/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

enum MusicService: String {
    
    case appleMusic
    case spotify
    
    func toString() -> String {
        if self == .spotify {
            return "Spotify"
        } else {
            return "Apple Music"
        }
    }
    
}
