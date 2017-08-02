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
    static weak var delegate: UpdatePartyDelegate?
    static var musicService = MusicService.spotify
    
    static var tracksQueue = [Track]() {
        didSet {
            delegate?.updateEveryonesTableView()
            if tracksQueue.count > 0 {
                delegate?.showCurrentlyPlayingArtwork()
            }
        }
    }
    static var tracksFromPeers = [Track]()
    static var danceability: Float = 0.5
    static var countryCode: String?
    
    // MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(Party.musicService.rawValue, forKey: "musicService")
        aCoder.encode(Party.danceability, forKey: "danceability")
        aCoder.encode(Party.countryCode, forKey: "countryCode")
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        let musicService = aDecoder.decodeObject(forKey: "musicService") as! String
        let danceability = aDecoder.decodeFloat(forKey: "danceability")
        let countryCode = aDecoder.decodeObject(forKey: "countryCode") as? String
        
        self.init()

        Party.musicService = MusicService(rawValue: musicService)!
        Party.danceability = danceability
        Party.countryCode = countryCode
    }
}
