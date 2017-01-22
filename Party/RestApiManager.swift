//
//  RestApiManager.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import Foundation
import StoreKit
import SwiftyJSON

class RestApiManager {
    
    private var url = "https://itunes.apple.com/search?media=music&term="
    private let serviceController = SKCloudServiceController()
    private var storefrontIdentifierFound = String()
    var tracksList = [Track]()
    let dispatchGroup = DispatchGroup()
    let secondDispatchGroup = DispatchGroup()
    
    
    func makeHTTPRequestToApple(withString string: String) {
        dispatchGroup.enter()
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            if self.storefrontIdentifierFound.isEmpty {
                self.secondDispatchGroup.enter()
                self.fetchStorefrontIdentifier()
                self.secondDispatchGroup.wait()
            }
            
            let requestURL = URL(string: self.url + string.replacingOccurrences(of: " ", with: "+") + "&s=" + self.storefrontIdentifierFound)
            
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
    
    func fetchStorefrontIdentifier() {
        serviceController.requestStorefrontIdentifier { (storefrontIdentifier, error) in
            if let storefrontId = storefrontIdentifier, storefrontId.characters.count >= 6 {
                let range = storefrontId.startIndex...storefrontId.index(storefrontId.startIndex, offsetBy: 5)
                self.storefrontIdentifierFound = storefrontId[range]
            }
            
            self.secondDispatchGroup.leave()
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
