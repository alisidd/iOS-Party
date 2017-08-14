//
//  SpotifyFetcher.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/2/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
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
                    let tracksJSON = JSON(data: data!)["tracks"]["items"].arrayValue
                    for trackJSON in tracksJSON {
                        guard self != nil else { return }
                        self!.tracksList.append(self!.parse(json: trackJSON))
                    }
                }
                completionHandler()
            }
            
            task.resume()
        }
    }
    
    func getMostPlayed(completionHandler: @escaping () -> Void) {
        getID(forCategoryID: "toplists") { [weak self] (ownerID, playlistID) in
            let request = SpotifyURLFactory.createPlaylistsRequest(forOwnerID: ownerID, forPlaylistID: playlistID)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let tracksJSON = JSON(data: data!)["tracks"]["items"].arrayValue
                    for (i, trackJSON) in tracksJSON.enumerated() where i < 20 {
                        guard self != nil else { return }
                        self!.tracksList.append(self!.parse(json: trackJSON["track"]))
                    }
                    completionHandler()
                }
            }
            
            task.resume()
        }
    }
    
    private func getID(forCategoryID categoryID: String, completionHandler: @escaping (String, String) -> Void) {
        let request = SpotifyURLFactory.createPlaylistsIDRequest(forCategoryID: categoryID)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let playlistsJSON = JSON(data: data!)["playlists"]["items"].arrayValue
                    if !playlistsJSON.isEmpty {
                        let playlistJSON = playlistsJSON[0]
                        let ownerID = playlistJSON["owner"]["id"].stringValue
                        let playlistID = playlistJSON["id"].stringValue
                        completionHandler(ownerID, playlistID)
                    }
                }
            }
            
            task.resume()
        }
    }
    
    func getUserAlbums(completionHandler: @escaping ([String : [Option]]) -> Void) {
        let request = SpotifyURLFactory.createUserAlbumsRequest()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var optionsDict = [String: [Option]]()
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let albumsJSON = JSON(data: data!)["items"].arrayValue
                    for albumJSON in albumsJSON {
                        let albumName = albumJSON["name"].stringValue
                        let tracksJSON = albumJSON["name"]["tracks"].arrayValue
                        
                        let key = String(albumName.characters.first ?? "#")
                        var tracks = [Track]()
                        
                        for trackJSON in tracksJSON {
                            guard self != nil else { return }
                            tracks.append(self!.parse(json: trackJSON))
                        }
                        
                        if optionsDict[key] != nil {
                            optionsDict[key]!.append(Option(name: albumName, tracks: tracks))
                        } else {
                            optionsDict[key] = [Option(name: albumName, tracks: tracks)]
                        }
                    }
                    completionHandler(optionsDict)
                }
            }
            
            task.resume()
        }
    }
    
    func getUserArtists(completionHandler: @escaping ([String : [Option]]) -> Void) {
        
    }
    
    func getUserPlaylists(completionHandler: @escaping ([String : [Option]]) -> Void) {
        let request = SpotifyURLFactory.createUserPlaylistsRequest()
        
        DispatchQueue.global(qos: .userInitiated).async {
            var optionsDict = [String: [Option]]()
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let playlistsJSON = JSON(data: data!)["items"].arrayValue
                    for playlistJSON in playlistsJSON {
                        let playlistName = playlistJSON["name"].stringValue
                        
                        let key = String(playlistName.characters.first ?? "#")
                        
                        let dummyTrack = Track()
                        dummyTrack.id = playlistJSON["owner"]["id"].stringValue //ownerID
                        dummyTrack.name = playlistJSON["id"].stringValue //playlstID
                        
                        if optionsDict[key] != nil {
                            optionsDict[key]!.append(Option(name: playlistName, tracks: [dummyTrack]))
                        } else {
                            optionsDict[key] = [Option(name: playlistName, tracks: [dummyTrack])]
                        }
                    }
                    completionHandler(optionsDict)
                }
            }
            
            task.resume()
        }
    }
    
    func getUserPlaylistTracks(forOwnerID ownerID: String, withPlaylistID playlistID: String, completionHandler: @escaping () -> Void) {
        let request = SpotifyURLFactory.createMyPlaylistsRequest(forOwnerID: ownerID, forPlaylistID: playlistID)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let tracksJSON = JSON(data: data!)["tracks"]["items"].arrayValue
                    for trackJSON in tracksJSON {
                        guard self != nil else { return }
                        self!.tracksList.append(self!.parse(json: trackJSON["track"]))
                    }
                    completionHandler()
                }
            }
        
            task.resume()
        }
    }
    
    func getUserTracks(completionHandler: @escaping () -> Void) {
        let request = SpotifyURLFactory.createUserTracksRequest()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let tracksJSON = JSON(data: data!)["items"].arrayValue
                    for trackJSON in tracksJSON {
                        guard self != nil else { return }
                        self!.tracksList.append(self!.parse(json: trackJSON["track"]))
                    }
                }
                completionHandler()
            }
            
            task.resume()
        }
    }
    
    func convert(userTracks: [Track], completionHandler: @escaping ([Track], [Track]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var userTracksFound = [Track]()
            var userTracksNotFound = [Track]()
            
            for userTrack in userTracks {
                let request = SpotifyURLFactory.createSearchRequest(forTerm: userTrack.name + " " + userTrack.artist)
                
                let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                        let tracksJSON = JSON(data: data!)["tracks"]["items"].arrayValue
                        guard self != nil else { return }
                        
                        if !tracksJSON.isEmpty {
                            userTracksFound.append(self!.parse(json: tracksJSON[0]))
                        } else {
                            userTracksNotFound.append(userTrack)
                        }
                    } else {
                        userTracksNotFound.append(userTrack)
                    }
                    
                    if userTracksFound.count + userTracksNotFound.count == userTracks.count {
                        userTracksFound = userTracksFound.filter({ !Party.tracksQueue(hasTrack: $0) })
                        DispatchQueue.main.async {
                            completionHandler(userTracksFound, userTracksNotFound)
                        }
                    }
                }
                
                task.resume()
            }
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
