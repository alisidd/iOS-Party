//
//  Track.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation

class Track: NSObject, NSCoding {
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
    
    static func fetchImage(fromURL urlString: String, completionHandler: @escaping (UIImage?) -> Void) {
        if let url = URL(string: urlString), let data = try? Data(contentsOf: url) {
            DispatchQueue.main.async {
                completionHandler(UIImage(data: data))
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
}
