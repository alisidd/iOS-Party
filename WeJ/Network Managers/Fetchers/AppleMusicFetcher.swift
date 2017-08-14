//
//  AppleMusicFetcher.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/31/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import MediaPlayer
import SwiftyJSON

protocol Fetcher {
    var tracksList: [Track] { get set }
    func searchCatalog(forTerm term: String, completionHandler: @escaping () -> Void)
    
    func getUserAlbums(completionHandler: @escaping ([String: [Option]]) -> Void)
    func getUserArtists(completionHandler: @escaping ([String: [Option]]) -> Void)
    func getUserPlaylists(completionHandler: @escaping ([String: [Option]]) -> Void)
    func getUserTracks(completionHandler: @escaping () -> Void)
    func convert(userTracks: [Track], completionHandler: @escaping ([Track], [Track]) -> Void)
    
    func getMostPlayed(completionHandler: @escaping () -> Void)
}

class AppleMusicFetcher: Fetcher {
    
    var tracksList = [Track]()
    var optionsDict = [String: [String]]()
    
    func searchCatalog(forTerm term: String, completionHandler: @escaping () -> Void) {
        let request = AppleMusicURLFactory.createSearchRequest(forTerm: term)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let tracksJSON = JSON(data: data!)["results"]["songs"]["data"].arrayValue
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
        let request = AppleMusicURLFactory.createMostPlayedRequest()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let chartsJSON = JSON(data: data!)["results"]["songs"]
                    if !chartsJSON.arrayValue.isEmpty {
                        let tracksJSON = chartsJSON.arrayValue[0]["data"].arrayValue
                        for trackJSON in tracksJSON {
                            guard self != nil else { return }
                            self!.tracksList.append(self!.parse(json: trackJSON))
                        }
                    }
                    completionHandler()
                }
            }
            
            task.resume()
        }
    }
    
    func getUserAlbums(completionHandler: @escaping ([String: [Option]]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let albums = MPMediaQuery.albums()
            albums.groupingType = .album
            let albumsList = albums.collections!
            
            var optionsDict = [String: [Option]]()
            
            for album in albumsList where !album.items.isEmpty {
                let albumName = album.items[0].albumTitle ?? "#"
                
                let key = String(albumName.characters.first!).uppercased()
                let tracks = Track.convert(tracks: album.items)
                
                if optionsDict[key] != nil {
                    optionsDict[key]!.append(Option(name: albumName, tracks: tracks))
                } else {
                    optionsDict[key] = [Option(name: albumName, tracks: tracks)]
                }
            }
            
            completionHandler(optionsDict)
        }
    }

    func getUserArtists(completionHandler: @escaping ([String: [Option]]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let artists = MPMediaQuery.artists()
            artists.groupingType = .artist
            let artistsList = artists.collections!
            
            var optionsDict = [String: [Option]]()
            
            for artist in artistsList where !artist.items.isEmpty {
                let artistName = artist.items[0].artist ?? "#"
                
                let key = String(artistName.characters.first!).uppercased()
                let tracks = Track.convert(tracks: artist.items)
                
                if optionsDict[key] != nil {
                    optionsDict[key]!.append(Option(name: artistName, tracks: tracks))
                } else {
                    optionsDict[key] = [Option(name: artistName, tracks: tracks)]
                }
            }
            
            completionHandler(optionsDict)
        }
    }
    
    func getUserPlaylists(completionHandler: @escaping ([String: [Option]]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let playlists = MPMediaQuery.playlists()
            playlists.groupingType = .playlist
            let playlistsList = playlists.collections!
            
            var optionsDict = [String: [Option]]()
            
            for playlist in playlistsList where !playlist.items.isEmpty {
                let playlistName = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "#"
                
                let key = String(playlistName.characters.first!)
                let tracks = Track.convert(tracks: playlist.items)
                
                if optionsDict[key] != nil {
                    optionsDict[key]!.append(Option(name: playlistName, tracks: tracks))
                } else {
                    optionsDict[key] = [Option(name: playlistName, tracks: tracks)]
                }
            }
            
            completionHandler(optionsDict)
        }
    }
    
    func getUserTracks(completionHandler: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let userTracks = MPMediaQuery.songs()
            let userTracksList = userTracks.collections!
            
            for userTrackCollection in userTracksList where !userTrackCollection.items.isEmpty {
                guard self != nil else { return }
                self?.tracksList.append(Track.convert(tracks: userTrackCollection.items)[0])
            }
            
            completionHandler()
        }
    }
    
    func convert(userTracks: [Track], completionHandler: @escaping ([Track], [Track]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var userTracksFound = [Track]()
            var userTracksNotFound = [Track]()
            
            for userTrack in userTracks {
                let request = AppleMusicURLFactory.createSearchRequest(forTerm: userTrack.name + " " + userTrack.artist)
                
                let task = URLSession.shared.dataTask(with: request) { (data, response, _) in   
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                        let tracksJSON = JSON(data: data!)["results"]["songs"]["data"].arrayValue
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
        let attributes = json["attributes"]
        
        track.id = json["id"].stringValue
        track.name = attributes["name"].stringValue
        track.artist = attributes["artistName"].stringValue
        
        track.lowResArtworkURL = getImageURL(fromURL: attributes["artwork"]["url"].stringValue, withSize: "60")
        
        if tracksList.count < AppleMusicConstants.maxInitialLowRes {
            Track.fetchImage(fromURL: track.lowResArtworkURL) { (image) in
                track.lowResArtwork = image
            }
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
