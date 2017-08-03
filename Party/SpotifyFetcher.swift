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
    let dispatchGroup = DispatchGroup()
    
    func searchCatalog(forTerm term: String) {
        tracksList.removeAll()
        let request = SpotifyURLFactory.createSearchRequest(forTerm: term)
        
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = JSON(data: data!)["tracks"]["items"].arrayValue
                    for trackJSON in json {
                        self.tracksList.append(self.parse(json: trackJSON))
                    }
                }
                self.dispatchGroup.leave()
            }
            
            task.resume()
        }
    }
    
    func getTrack(forID id: String) {
        let request = SpotifyURLFactory.createTrackRequest(forID: id)
        
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = JSON(data: data!)
                    self.tracksList.append(self.parse(json: json))
                }
                self.dispatchGroup.leave()
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
                if tracksList.count < 5 {
                    track.lowResArtwork = Track.fetchImage(fromURL: track.lowResArtworkURL)
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
