//
//  Party.swift
//  Party
//
//  Created by Matthew Paletta on 2016-11-14.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

class Party: NSObject, NSCoding {
    static weak var delegate: UpdatePartyDelegate?
    static var musicService = MusicService.spotify
    
    static var tracksQueue = [Track]() {
        didSet {
            delegate?.updateEveryonesTableView()
            if !tracksQueue.isEmpty {
                delegate?.showCurrentlyPlayingArtwork()
            }
            if oldValue.isEmpty && !tracksQueue.isEmpty || tracksQueue.count == 1 {
                delegate?.lyricsAndQueueVC.minimizeTracksTable()
            }
        }
    }
    static var tracksFromMyself = [Track]()
    static var danceability: Float = 0.5
    static var cookie: String? // Represents Spotify access token or Apple Music country code
    
    static func reset() {
        musicService = .spotify
        tracksQueue.removeAll()
        tracksFromMyself.removeAll()
        danceability = 0.5
        cookie = nil
    }
    
    // MARK: - NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(Party.musicService.rawValue, forKey: "musicService")
        aCoder.encode(Party.danceability, forKey: "danceability")
        aCoder.encode(Party.cookie, forKey: "cookie")
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        let musicService = aDecoder.decodeObject(forKey: "musicService") as! String
        let danceability = aDecoder.decodeFloat(forKey: "danceability")
        let cookie = aDecoder.decodeObject(forKey: "cookie") as? String
        
        self.init()

        Party.musicService = MusicService(rawValue: musicService)!
        Party.danceability = danceability
        Party.cookie = cookie
    }
}
