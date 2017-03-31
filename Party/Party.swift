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

@objc(Party)
class Party: NSObject, NSCoding {
    weak var delegate: UpdatePartyDelegate?
    var musicService = MusicService.spotify
    
    
    var tracksQueue = [Track]() {
        didSet {
            delegate?.updateEveryonesTableView()
            if tracksQueue.count > 0 {
                delegate?.showCurrentlyPlayingArtwork()
            }
        }
    }
    var tracksFromPeers = [Track]()
    var danceability: Float = 0.5
    
    // MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.musicService.rawValue, forKey: "musicService")
        aCoder.encode(self.danceability, forKey: "danceability")
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        let musicService = aDecoder.decodeObject(forKey: "musicService") as! String
        let danceability = aDecoder.decodeFloat(forKey: "danceability")
        
        self.init()

        self.musicService = MusicService(rawValue: musicService)!
        self.danceability = danceability
    }
}
