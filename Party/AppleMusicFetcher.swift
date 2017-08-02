//
//  AppleMusicFetcher.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/31/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol Fetcher {
    var tracksList: [Track] { get set }
    var dispatchGroup: DispatchGroup { get }
    func searchCatalog(forTerm term: String)
    func getTrack(forID id: String)
}

class AppleMusicFetcher: Fetcher {
    var tracksList = [Track]()
    let dispatchGroup = DispatchGroup()
    
    func searchCatalog(forTerm term: String) {
        let request = AppleMusicURLFactory.createSearchRequest(forTerm: term)
        
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = JSON(data: data!)["results"]["songs"]["data"].arrayValue
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
        let request = AppleMusicURLFactory.createTrackRequest(forID: id)
        
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = JSON(data: data!)["data"].arrayValue
                    self.tracksList.append(self.parse(json: json[0]))
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
        
        track.lowResArtworkURL = getImageURL(fromURL: attributes["artwork"]["url"].stringValue, withSize: "60")
        
        if tracksList.count < 5 {
            track.lowResArtwork = Track.fetchImage(fromURL: track.lowResArtworkURL)
        }
        
        track.highResArtworkURL = getImageURL(fromURL: attributes["artwork"]["url"].stringValue, withSize: "400")
        track.length = TimeInterval(attributes["durationInMillis"].doubleValue / 1000)
        
        return track
    }
    
    private func getImageURL(fromURL url: String, withSize size: String) -> String {
        var url = url
        
        url = url.replacingOccurrences(of: "{w}", with: size)
        url = url.replacingOccurrences(of: "{h}", with: size)
        
        return url
    }
}
