//
//  Track.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import MediaPlayer

class Track: NSObject, NSCoding, NSCopying {
    
    var id = String()
    var name = String()
    var artist = String()
    
    var lowResArtworkURL = String()
    var lowResArtwork: UIImage?
    
    var highResArtworkURL = String()
    var highResArtwork: UIImage?
    
    var length: TimeInterval?
    
    static func typeOf(track: Track) -> RequestType {
        return track.id.hasPrefix("R:") ? .removal : .addition
    }
    
    static func convert(tracks: [MPMediaItem]) -> [Track] {
        var newTracks = [Track]()
        
        for track in tracks {
            let newTrack = Track()
            
            newTrack.id = String(track.persistentID)
            newTrack.name = track.title ?? ""
            newTrack.artist = track.artist ?? ""
            newTrack.lowResArtwork = track.artwork?.image(at: CGSize(width: 60, height: 60)) ?? #imageLiteral(resourceName: "stockArtwork")
            
            newTracks.append(newTrack)
        }
        
        return newTracks
    }
    
    static func fetchImage(fromURL urlString: String, completionHandler: @escaping (UIImage?) -> Void) {
        if let url = URL(string: urlString), let data = try? Data(contentsOf: url) {
            DispatchQueue.main.async {
                completionHandler(UIImage(data: data))
            }
        } else {
            DispatchQueue.main.async {
                completionHandler(#imageLiteral(resourceName: "stockArtwork"))
            }
        }
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(id, forKey: "id")
        aCoder.encode(name, forKey: "name")
        aCoder.encode(artist, forKey: "artist")
        aCoder.encode(lowResArtworkURL, forKey: "lowResArtworkURL")
        aCoder.encode(lowResArtwork, forKey: "lowResArtwork")
        aCoder.encode(highResArtworkURL, forKey: "highResArtworkURL")
        aCoder.encode(highResArtwork, forKey: "highResArtwork")
        aCoder.encode(length, forKey: "length")
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        let id = aDecoder.decodeObject(forKey: "id") as! String
        let name = aDecoder.decodeObject(forKey: "name") as! String
        let artist = aDecoder.decodeObject(forKey: "artist") as! String
        let lowResArtworkURL = aDecoder.decodeObject(forKey: "lowResArtworkURL") as! String
        let lowResArtwork = aDecoder.decodeObject(forKey: "lowResArtwork") as? UIImage
        let highResArtworkURL = aDecoder.decodeObject(forKey: "highResArtworkURL") as! String
        let highResArtwork = aDecoder.decodeObject(forKey: "highResArtwork") as? UIImage
        let length = aDecoder.decodeObject(forKey: "length") as? TimeInterval
        
        self.init()
        
        self.id = id
        self.name = name
        self.artist = artist
        self.lowResArtworkURL = lowResArtworkURL
        self.lowResArtwork = lowResArtwork
        self.highResArtworkURL = highResArtworkURL
        self.highResArtwork = highResArtwork
        self.length = length
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Track()
        copy.id = id
        copy.name = name
        copy.artist = artist
        
        copy.lowResArtworkURL = lowResArtworkURL
        copy.lowResArtwork = lowResArtwork
        copy.highResArtworkURL = highResArtworkURL
        copy.highResArtwork = highResArtwork
        
        copy.length = length
        return copy
    }
}
