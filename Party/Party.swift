//
//  Party.swift
//  Party
//
//  Created by Matthew on 2016-11-14.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import Foundation

enum MusicService: String {
    case appleMusic
    case spotify
}

class Party: NSObject {
    weak var delegate: UpdatePartyDelegate?
    var genres = [String]()
    var musicService = MusicService.spotify
    
    
    var tracksQueue = [Track]() {
        didSet {
            delegate?.updateEveryonesTableView()
            if tracksQueue.count == 0 {
                delegate?.hideCurrentlyPlayingArtwork()
            } else {
                delegate?.showCurrentlyPlayingArtwork()
            }
        }
    }
    var tracksFromPeers = [Track]()
    var isSorted = false
    
    var numPeople = 0
    var password: String?
    var isLocked = false
}
