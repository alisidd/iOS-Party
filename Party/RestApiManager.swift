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
        url += string.replacingOccurrences(of: " ", with: "+")
        
        let requestURL = URL(string: url)
        
        let task = URLSession.shared.dataTask(with: requestURL!) { (data, response, error) in
            let statusCode = (response as! HTTPURLResponse).statusCode
            
            if statusCode == 200 {
                let json = JSON(data: data!)
                self.parseAppleJSON(forJSON: json)
            }
            self.dispatchGroup.leave()
        }
        
        task.resume()
    }
    
    func parseAppleJSON(forJSON json: JSON) {
        tracksList.removeAll()
        for track in json["results"].arrayValue {
            let newTrack = Track()
            newTrack.id = track["trackId"].intValue
            newTrack.name = track["trackName"].stringValue
            newTrack.artist = track["artistName"].stringValue
            newTrack.album = track["collectionName"].stringValue
            
            tracksList.append(newTrack)
        }
    }
}
