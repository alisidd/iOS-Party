//
//  SpotifyFetcher.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/2/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation
import SwiftyJSON

class SpotifyFetcher: Fetcher {
    var tracksList = [Track]()
    
    func searchCatalog(forTerm term: String, completionHandler: @escaping () -> Void) {
        let request = SpotifyURLFactory.createSearchRequest(forTerm: term)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = JSON(data: data!)["tracks"]["items"].arrayValue
                    for trackJSON in json {
                        guard self != nil else { return }
                        self!.tracksList.append(self!.parse(json: trackJSON))
                    }
                    completionHandler()
                }
            }
            
            task.resume()
        }
    }
    
    private func parse(json: JSON) -> Track {
        let track = Track()
        
        track.id = json["id"].stringValue
        track.name = json["name"].stringValue
        track.artist = json["artists"].arrayValue[0]["name"].stringValue
        
        for images in json["album"]["images"].arrayValue {
            if images["height"].stringValue == "64" {
                track.lowResArtworkURL = images["url"].stringValue
                if tracksList.count < SpotifyConstants.maxInitialLowRes {
                    Track.fetchImage(fromURL: track.lowResArtworkURL) { (image) in
                        track.lowResArtwork = image
                    }
                }
            }
            
            if images["height"].stringValue == "640" {
                track.highResArtworkURL = images["url"].stringValue
            }
        }
        
        track.length = TimeInterval(json["duration_ms"].doubleValue / 1000)
        
        return track
    }
}
