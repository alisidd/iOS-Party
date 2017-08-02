//
//  AppleMusicFetcher.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/31/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation
import SwiftyJSON

class AppleMusicFetcher {
    var tracksList = [Track]()
    let dispatchGroup = DispatchGroup()
    
    func getTrack(forID id: String) {
        let request = AppleMusicURLFactory.createTrackRequest(forID: id)
        
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print(statusCode)
                    if statusCode == 200 {
                        let json = JSON(data: data!)["data"].arrayValue[0]
                        print(json)
                        self.tracksList.append(self.parse(json: json))
                    }
                }
                self.dispatchGroup.leave()
            }
            
            task.resume()
        }
    }
    
    private func parse(json: JSON) -> Track {
        let track = Track()
        let attributes = json["attributes"]
        
        track.id = json["id"].stringValue
        track.name = attributes["name"].stringValue
        track.artist = attributes["artistName"].stringValue
        
        track.lowResArtworkURL = getImageURL(forURL: attributes["artwork"]["url"].stringValue, withSize: "60")
        
        if tracksList.count < 5 {
            track.lowResArtwork = Track.fetchImage(fromURL: track.lowResArtworkURL)
        }
        
        track.highResArtworkURL = getImageURL(forURL: attributes["artwork"]["url"].stringValue, withSize: "400")
        track.length = TimeInterval(attributes["trackTimeMillis"].doubleValue / 1000)
        
        return track
    }
    
    private func getImageURL(forURL url: String, withSize size: String) -> String {
        var url = url
        
        url = url.replacingOccurrences(of: "{w}", with: size)
        url = url.replacingOccurrences(of: "{h}", with: size)
        
        return url
    }
}
