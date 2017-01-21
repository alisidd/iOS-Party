//
//  RestApiManager.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation
import SwiftyJSON

class RestApiManager {
    
    private var url = "https://itunes.apple.com/search?media=music&term="
    var tracksList = [Track]()
    let dispatchGroup = DispatchGroup()
    
    
    func makeHTTPRequestToApple(withString string: String) {
        dispatchGroup.enter()

        let requestURL = URL(string: url + string.replacingOccurrences(of: " ", with: "+"))
        
        DispatchQueue.global(qos: .background).async {
            let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    if statusCode == 200 {
                        let json = JSON(data: data!)
                        self.parseAppleJSON(forJSON: json)
                    }
                }
                
                self.dispatchGroup.leave()
            }
            task.resume()
        }
    }
    
    func parseAppleJSON(forJSON json: JSON) {
        tracksList.removeAll()
        for track in json["results"].arrayValue {
            let newTrack = Track()
            newTrack.id = track["trackId"].intValue
            newTrack.name = track["trackName"].stringValue
            newTrack.artist = track["artistName"].stringValue
            newTrack.album = track["collectionName"].stringValue
            
            newTrack.lowResArtworkURL = track["artworkUrl100"].stringValue
            newTrack.highResArtworkURL = newTrack.lowResArtworkURL.replacingOccurrences(of: "100x100", with: "600x600")
            
            tracksList.append(newTrack)
        }
    }
}
