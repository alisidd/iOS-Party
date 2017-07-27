//
//  Party.swift
//  Party
//
//  Created by Matthew Paletta on 2016-11-14.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

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
        aCoder.encode(musicService.rawValue, forKey: "musicService")
        aCoder.encode(danceability, forKey: "danceability")
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        let musicService = aDecoder.decodeObject(forKey: "musicService") as! String
        let danceability = aDecoder.decodeFloat(forKey: "danceability")
        
        self.init()

        self.musicService = MusicService(rawValue: musicService)!
        self.danceability = danceability
    }
}
