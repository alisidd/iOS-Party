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
    
    private static var templateWebRequest: (URLRequest, @escaping (Data?, URLResponse?, Error?) -> Void) -> Void = { (request, completionHandler) in
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200, data != nil {
                    completionHandler(data, response, error)
                }
            }
            
            task.resume()
        }
    }
    
    func searchCatalog(forTerm term: String, completionHandler: @escaping () -> Void) {
        let request = SpotifyURLFactory.createSearchRequest(forTerm: term)
        
        SpotifyFetcher.templateWebRequest(request) { [weak self] (data, response, _) in
            let tracksJSON = try! JSON(data: data!)["tracks"]["items"].arrayValue
            for trackJSON in tracksJSON {
                guard self != nil else { return }
                self!.tracksList.append(self!.parse(json: trackJSON))
            }
            completionHandler()
        }
    }
    
    func getLibraryAlbums(completionHandler: @escaping ([String : [Option]]) -> Void) {
        let request = SpotifyURLFactory.createLibraryAlbumsRequest()
        
        SpotifyFetcher.templateWebRequest(request) { [weak self] (data, response, _) in
            var optionsDict = [String: [Option]]()
            
            let albumsJSON = try! JSON(data: data!)["items"].arrayValue
            for albumJSON in albumsJSON {
                let albumName = albumJSON["name"].stringValue
                let tracksJSON = albumJSON["name"]["tracks"].arrayValue
                
                let key = String(albumName.first ?? "#")
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
    
    func getLibraryArtists(completionHandler: @escaping ([String : [Option]]) -> Void) {
        
    }
    
    func getLibraryPlaylists(completionHandler: @escaping ([String : [Option]]) -> Void) {
        let request = SpotifyURLFactory.createLibraryPlaylistsRequest()
        
        SpotifyFetcher.templateWebRequest(request) { (data, response, _) in
            var optionsDict = [String: [Option]]()
            
            let playlistsJSON = try! JSON(data: data!)["items"].arrayValue
            for playlistJSON in playlistsJSON {
                let playlistName = playlistJSON["name"].stringValue
                
                let key = String(playlistName.first ?? "#")
                
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
    
    func getLibraryPlaylistTracks(atOffset offset: Int, forOwnerID ownerID: String, forPlaylistID playlistID: String, completionHandler: @escaping () -> Void) {
        let request = SpotifyURLFactory.createLibraryPlaylistTracksRequest(atOffset: offset, forOwnerID: ownerID, forPlaylistID: playlistID)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = try! JSON(data: data!)
                    let tracksJSON = json["items"].arrayValue
                    for trackJSON in tracksJSON {
                        guard self != nil else { return }
                        self!.tracksList.append(self!.parse(json: trackJSON["track"]))
                    }
                    
                    if json["total"].intValue > offset + 100 {
                        self?.getLibraryPlaylistTracks(atOffset: offset + 100, forOwnerID: ownerID, forPlaylistID: playlistID, completionHandler: completionHandler)
                    } else {
                        completionHandler()
                    }
                } else {
                    completionHandler()
                }
            }
            
            task.resume()
        }
    }
    
    func getLibraryTracks(atOffset offset: Int, completionHandler: @escaping () -> Void) {
        let request = SpotifyURLFactory.createLibraryTracksRequest(atOffset: offset)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = try! JSON(data: data!)
                    let tracksJSON = json["items"].arrayValue
                    for trackJSON in tracksJSON {
                        guard self != nil else { return }
                        self!.tracksList.append(self!.parse(json: trackJSON["track"]))
                    }
                    
                    if json["total"].intValue > offset + 50 {
                        self?.getLibraryTracks(atOffset: offset + 50, completionHandler: completionHandler)
                    } else {
                        completionHandler()
                    }
                } else {
                    completionHandler()
                }
            }
            
            task.resume()
        }
    }
    
    func convert(libraryTracks: [Track], trackHandler: @escaping (Track) -> Void, errorHandler: @escaping (Int) -> Void) {
        let dispatchGroup = DispatchGroup()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var notFoundCount = 0
            
            for (i, libraryTrack) in libraryTracks.enumerated() {
                let request = SpotifyURLFactory.createSearchRequest(forTerm: libraryTrack.name + " " + libraryTrack.artist)
                
                dispatchGroup.enter()
                let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                        let tracksJSON = try! JSON(data: data!)["tracks"]["items"].arrayValue
                        guard self != nil else { return }
                        
                        if !tracksJSON.isEmpty {
                            let track = self!.parse(json: tracksJSON[0])
                            if !Party.tracksQueue(hasTrack: track) {
                                DispatchQueue.main.async {
                                    trackHandler(track)
                                }
                            }
                        } else {
                            notFoundCount += 1
                        }
                    } else {
                        notFoundCount += 1
                    }
                    
                    if i == libraryTracks.count - 1 {
                        DispatchQueue.main.async {
                            errorHandler(notFoundCount)
                        }
                    }
                    dispatchGroup.leave()
                }
                
                task.resume()
                dispatchGroup.wait()
            }
        }
    }
    
    func getMostPlayed(completionHandler: @escaping () -> Void) {
        getID(forCategoryID: "toplists") { [weak self] (ownerID, playlistID) in
            let request = SpotifyURLFactory.createPlaylistsRequest(forOwnerID: ownerID, forPlaylistID: playlistID)
            
            SpotifyFetcher.templateWebRequest(request) {(data, response, _) in
                let tracksJSON = try! JSON(data: data!)["tracks"]["items"].arrayValue
                for (i, trackJSON) in tracksJSON.enumerated() where i < 20 {
                    guard self != nil else { return }
                    self!.tracksList.append(self!.parse(json: trackJSON["track"]))
                }
                completionHandler()
            }
        }
    }
    
    private func getID(forCategoryID categoryID: String, completionHandler: @escaping (String, String) -> Void) {
        let request = SpotifyURLFactory.createPlaylistsIDRequest(forCategoryID: categoryID)
        
        SpotifyFetcher.templateWebRequest(request) { (data, response, _) in
            let playlistsJSON = try! JSON(data: data!)["playlists"]["items"].arrayValue
            if let playlistJSON = playlistsJSON.first {
                let ownerID = playlistJSON["owner"]["id"].stringValue
                let playlistID = playlistJSON["id"].stringValue
                completionHandler(ownerID, playlistID)
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
