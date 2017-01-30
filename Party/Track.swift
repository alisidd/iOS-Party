//
//  Song.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import Foundation

class Track: NSObject {
    weak var delegate: UpdateTableDelegate?
    var id = String()
    var name = String()
    var artist = String()
    var album = String()
    
    var lowResArtworkURL = String()
    var artwork: UIImage?
    
    var highResArtworkURL = String()
    var highResArtwork: UIImage? {
        didSet {
            print("Delegate called")
            delegate?.reloadTableIfPlayingTrack()
        }
    }
    
    var danceability: Int?
    
    static func idOfTracks(_ tracks: [Track]) -> [String] {
        var result = [String]()
        for track in tracks {
            result.append(track.id)
        }
        return result
    }
}
