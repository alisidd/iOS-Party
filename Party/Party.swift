//
//  Party.swift
//  Party
//
//  Created by Matthew on 2016-11-14.
//  Copyright © 2016 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

enum MusicService {
    case appleMusic
    case spotify
}

class Party: NSObject {
    weak var delegate: UpdatePartyDelegate?
    var partyName = String()
    var genres = [String]()
    var musicService = MusicService.spotify
    
    var tracksQueue = [Track]() {
        didSet {
            self.delegate?.updateEveryonesTableView()
        }
    }
    var tracksFromPeers = [Track]()
    var isSorted = false
    
    var numPeople = 0
    var password: String?
    var isLocked = false
}
