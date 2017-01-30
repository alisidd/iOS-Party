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

class Party: NSObject, NSCoding {
    
    // MARK: - General Variables
    
    var partyName = String()
    var genres = [String]()
    var musicService = MusicService.spotify
    weak var delegate: UpdatePartyDelegate?
    
    var tracksQueue = [Track]() {
        didSet {
            delegate?.updateEveryonesTableView()
        }
    }
    var tracksFromPeers = [Track]()
    var isSorted = false
    
    var numPeople = 0
    var password: String?
    var isLocked = false
    
    override init() {
        
    }
    
    // MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        if let unwrappedDelegate = self.delegate {
            aCoder.encode(unwrappedDelegate, forKey: "delegate")
        }
        aCoder.encode(partyName, forKey: "partyName")
        aCoder.encode(genres, forKey: "genres")
        aCoder.encode(musicService.rawValue, forKey: "musicService")
        aCoder.encode(Track.idOfTracks(tracksQueue), forKey: "tracksQueue")
        aCoder.encode(Track.idOfTracks(tracksFromPeers), forKey: "tracksFromPeers")
        aCoder.encode(isSorted, forKey: "isSorted")
        aCoder.encode(numPeople, forKey: "numPeople")
        
        if let unwrappedPassword = password {
            aCoder.encode(unwrappedPassword, forKey: "password")
        }
        
        aCoder.encode(isLocked, forKey: "isLocked")
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        if let unwrappedDelegate = aDecoder.decodeObject(forKey: "delegate") as? UpdatePartyDelegate {
            self.delegate = unwrappedDelegate
        }
        
        self.partyName = (aDecoder.decodeObject(forKey: "partyName") as? String)!
        self.genres = (aDecoder.decodeObject(forKey: "genres") as? [String])!
        self.musicService = MusicService(rawValue: (aDecoder.decodeObject(forKey: "musicService") as? String)!)!
        self.delegate?.addTracksFromPeer(withTracks: (aDecoder.decodeObject(forKey: "tracksQueue") as? [String])!)
        self.delegate?.addTracksFromPeer(withTracks: (aDecoder.decodeObject(forKey: "tracksFromPeers") as? [String])!)
        self.isSorted = (aDecoder.decodeObject(forKey: "isSorted") as? Bool)!
        self.numPeople = (aDecoder.decodeObject(forKey: "numPeople") as? Int)!
        
        if let password = aDecoder.decodeObject(forKey: "password") as? String {
            self.password = password
        }
        
        self.isLocked = (aDecoder.decodeObject(forKey: "isLocked") as? Bool)!
    }

}
