//
//  Party.swift
//  Party
//
//  Created by Matthew on 2016-11-14.
//  Copyright © 2016 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation

enum MusicService: String {
    case appleMusic
    case spotify
}

class Party: NSObject, NSCoding {
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
    
    override init() {
        
    }
    
    // Encode
    func encode(with aCoder: NSCoder) {
        print("ENCODING")
        if let unwrappedDelegate = self.delegate {
            aCoder.encode(unwrappedDelegate, forKey: "delegate")
        }
        print("1")
        aCoder.encode(partyName, forKey: "partyName")
        print("2")
        aCoder.encode(genres, forKey: "genres")
        print("3")
        aCoder.encode(musicService.rawValue, forKey: "musicService")
        print("4")
        aCoder.encode(Party.idOfTracks(tracksQueue), forKey: "tracksQueue")
        print("5")
        aCoder.encode(Party.idOfTracks(tracksFromPeers), forKey: "tracksFromPeers")
        print("6")
        aCoder.encode(isSorted, forKey: "isSorted")
        aCoder.encode(numPeople, forKey: "numPeople")
        
        if let unwrappedPassword = password {
            aCoder.encode(unwrappedPassword, forKey: "password")
        }
        
        aCoder.encode(isLocked, forKey: "isLocked")
    }
    
    // Decode
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
        //self.isSorted = (aDecoder.decodeObject(forKey: "isSorted") as? Bool)!
        //self.numPeople = (aDecoder.decodeObject(forKey: "numPeople") as? Int)!
        
        if let password = aDecoder.decodeObject(forKey: "password") as? String {
            self.password = password
        }
        
        //self.isLocked = (aDecoder.decodeObject(forKey: "isLocked") as? Bool)!
    }
    
    static func idOfTracks(_ tracks: [Track]) -> [String] {
        var result = [String]()
        for track in tracks {
            result.append(track.id)
        }
        return result
    }
}
