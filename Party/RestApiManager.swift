//
//  RestApiManager.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import StoreKit
import SwiftyJSON
import MultipeerConnectivity

class RestApiManager {
    
    // Apple Music Variables
    private var appleTracksUrl = "https://itunes.apple.com/search?media=music&term="
    private let serviceController = SKCloudServiceController()
    
    // Spotify Variables
    private var spotifyTracksUrl = "https://api.spotify.com/v1/"
    private var spotifyRecommendationsUrl = "https://api.spotify.com/v1/recommendations?"
    
    // General Variables
    var tracksList = [Track]()

    // Asynchronous Variables
    let dispatchGroup = DispatchGroup()
    
    // MARK: - Apple Music
    
    func makeHTTPRequestToApple(withString string: String, withPossibleTrackID trackID: String?) {
        dispatchGroup.enter()
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Get storefront identifer to ensure tracks returned are playable by the user
            let storefrontIdentifierFound = Party.countryCode
            let term = string.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
            
            let requestURL = URL(string: self.appleTracksUrl + term.replacingOccurrences(of: " ", with: "+") + "&s=" + storefrontIdentifierFound!)
            
            if let unwrappedURL = requestURL {
                let task = URLSession.shared.dataTask(with: unwrappedURL) { (data, response, error) in
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        if statusCode == 200 {
                            let json = JSON(data: data!)
                            self.parseAppleTrackJSON(forJSON: json, possibleTrackID: trackID)
                        }
                    }
                    
                    self.dispatchGroup.leave()
                }
                
                task.resume()
            } else {
                self.dispatchGroup.leave()
            }
        }
    }
    
    func parseAppleTrackJSON(forJSON json: JSON, possibleTrackID: String?) {
        if possibleTrackID == nil {
            tracksList.removeAll()
        }
        
        for track in json["results"].arrayValue {
            let newTrack = Track()
            newTrack.id = track["trackId"].stringValue
            newTrack.name = track["trackName"].stringValue
            newTrack.artist = track["artistName"].stringValue
            newTrack.album = track["collectionName"].stringValue
            
            //print("Fetched \(newTrack.name)")
            
            if possibleTrackID != nil && possibleTrackID! != newTrack.id {
                continue
            }
            
            newTrack.lowResArtworkURL = track["artworkUrl60"].stringValue
            
            if tracksList.count < 5 {
                newTrack.lowResArtwork = fetchImage(fromURL: newTrack.lowResArtworkURL)
            }
            
            newTrack.highResArtworkURL = newTrack.lowResArtworkURL.replacingOccurrences(of: "60x60", with: "400x400")
            
            newTrack.length = TimeInterval(track["trackTimeMillis"].doubleValue / 1000)
            
            tracksList.append(newTrack)
        }
    }
    
    func makeHTTPRequestToAppleForSingleTrack(forID id: String) {
        let ids = id.components(separatedBy: ":")[1].components(separatedBy: "-")
        let trackID = ids[0]
        let artistName = ids[1]
        makeHTTPRequestToApple(withString: artistName, withPossibleTrackID: trackID)
    }
    
    // MARK: - Spotify
    
    func makeHTTPRequestToSpotify(withString string: String) {
        if SpotifyAuthorizationManager.spotifyAccessToken.isEmpty {
            print("Authorizing")
            SpotifyAuthorizationManager.authorizeSpotifyAccess()
            SpotifyAuthorizationManager.dispatchGroup.wait()
        }
        dispatchGroup.enter()
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            let term = string.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
            
            var request = URLRequest(url: URL(string: self.spotifyTracksUrl + "search?q=" + term.replacingOccurrences(of: " ", with: "+") + "&type=track")!)
            request.addValue("Bearer \(SpotifyAuthorizationManager.spotifyAccessToken)", forHTTPHeaderField: "Authorization")
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    if statusCode == 200 {
                        let json = JSON(data: data!)
                        self.parseMultipleSpotifyTracksJSON(forJSON: json)
                    }
                }
                self.dispatchGroup.leave()
            }
                
            task.resume()
        }
    }
    
    func parseMultipleSpotifyTracksJSON(forJSON json: JSON) {
        tracksList.removeAll()
        for (type,subJson):(String, JSON) in json["tracks"] {
            if type == "items" {
                for track in subJson.arrayValue {
                    let newTrack = Track()
                    
                    newTrack.id = track["id"].stringValue
                    newTrack.name = track["name"].stringValue
                    newTrack.album = track["album"]["name"].stringValue
                    
                    for artists in track["artists"].arrayValue {
                        newTrack.artist = artists["name"].stringValue
                        break
                    }
                    
                    for images in track["album"]["images"].arrayValue {
                        if images["height"].stringValue == "640" {
                            newTrack.highResArtworkURL = images["url"].stringValue
                        }
                        if images["height"].stringValue == "64" {
                            newTrack.lowResArtworkURL = images["url"].stringValue
                            newTrack.lowResArtwork = fetchImage(fromURL: newTrack.lowResArtworkURL)
                        }
                    }
                    
                    newTrack.length = TimeInterval(track["duration_ms"].doubleValue / 1000)
                    
                    tracksList.append(newTrack)
                }
            } else if subJson["type"] == "track" {
                // Dealing with recommendations' json
                makeHTTPRequestToSpotifyForSingleTrack(forID: subJson["id"].stringValue, shouldFetchLowRes: false)
            }
        }
    }
    
    func fetchImage(fromURL urlString: String) -> UIImage? {
        if let url = URL(string: urlString) {
            do {
                let data = try Data(contentsOf: url)
                return UIImage(data: data)
            } catch {
                print("Error trying to get data from Artwork URL")
            }
        }
        return nil
    }
    
    func makeHTTPRequestToSpotifyForSingleTrack(forID id: String, shouldFetchLowRes fetchLowRes: Bool = true) {
        if SpotifyAuthorizationManager.spotifyAccessToken.isEmpty {
            print("Authorizing")
            SpotifyAuthorizationManager.authorizeSpotifyAccess()
            SpotifyAuthorizationManager.dispatchGroup.wait()
        }
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            var requestURL = URLRequest(url: URL(string: self.spotifyTracksUrl + "tracks/" + id.components(separatedBy: ":")[1])!)
            requestURL.addValue("Bearer \(SpotifyAuthorizationManager.spotifyAccessToken)", forHTTPHeaderField: "Authorization")
            requestURL.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: requestURL) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    if statusCode == 200 {
                        let json = JSON(data: data!)
                        self.parseSingleSpotifyTrackJSON(forTrack: json, shouldFetchLowRes: fetchLowRes)
                    }
                }
                self.dispatchGroup.leave()
            }
                
            task.resume()
        }
    }
    
    func parseSingleSpotifyTrackJSON(forTrack track: JSON, shouldFetchLowRes fetchLowRes: Bool = true) {
        let newTrack = Track()
        
        newTrack.id = track["id"].stringValue
        newTrack.name = track["name"].stringValue
        newTrack.album = track["album"]["name"].stringValue
        
        for artists in track["artists"].arrayValue { //get other artists too
            newTrack.artist = artists["name"].stringValue
            break
        }
        
        for images in track["album"]["images"].arrayValue {
            if images["height"].stringValue == "64" {
                newTrack.lowResArtworkURL = images["url"].stringValue
                if fetchLowRes {
                    newTrack.lowResArtwork = fetchImage(fromURL: newTrack.lowResArtworkURL)
                }
            }
           
            if images["height"].stringValue == "300" {
                newTrack.mediumResArtworkURL = images["url"].stringValue
            } else {
                if !fetchLowRes {
                    newTrack.lowResArtwork = fetchImage(fromURL: newTrack.lowResArtworkURL)
                }
            }
            
            if images["height"].stringValue == "640" {
                newTrack.highResArtworkURL = images["url"].stringValue
            }
        }
        
        newTrack.length = TimeInterval(track["duration_ms"].doubleValue / 1000)
        
        tracksList.append(newTrack)
    }
    
    func makeHTTPRequestToSpotifyForRecommendations(withTracks tracks: [Track], forDanceability danceability: Float) {
        /*let tracksId = idOfTracks(forTracks: tracks)
        if RestApiManager.spotifyAccessToken == nil {
            print("Authorizing")
            authorizeSpotifyAccess()
            dispatchGroup.wait()
        }
        getRecommendedTracks(withTracksId: tracksId, forDanceability: danceability)*/
    }
    
    func idOfTracks(forTracks tracks: [Track]) -> [String] {
        var tracksId = [String]()
        
        for index in 0...4 {
            if let track = tracks[safe: index] {
                tracksId.append(track.id)
            }
        }
        
        return tracksId
    }
    
    func getRecommendedTracks(withTracksId tracksId: [String], forDanceability danceability: Float) {
        let request = getRequestForRecommendations(withTracksId: tracksId, forDanceability: danceability)
        
        dispatchGroup.enter()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    if statusCode == 200 {
                        let json = JSON(data: data!)
                        self.parseMultipleSpotifyTracksJSON(forJSON: json)
                    }
                }
                self.dispatchGroup.leave()
            }
            
            task.resume()
        }
        
    }
    
    func getRequestForRecommendations(withTracksId tracksId: [String], forDanceability danceability: Float) -> URLRequest {
        var request = URLRequest(url: URL(string: spotifyRecommendationsUrl + "seed_tracks=" + tracksId.joined(separator: ",") + "&target_danceability=" + String(format: "%.2f", danceability) + "&min_popularity=50&market=US")!)
        request.addValue("Bearer \(SpotifyAuthorizationManager.spotifyAccessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        return request
    }
}
