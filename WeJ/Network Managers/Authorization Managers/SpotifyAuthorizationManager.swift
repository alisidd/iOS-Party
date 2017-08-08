//
//  SpotifyAuthorizationManager.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 7/26/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import Foundation
import SafariServices
import SwiftyJSON

class SpotifyAuthorizationManager: NSObject, AuthorizationManager, SPTAudioStreamingDelegate {
    static weak var delegate: ViewControllerAccessDelegate?
    
    private static var authViewController: SFSafariViewController!
    private static let updateSession: (Error?, SPTSession?) -> Void = { (error, session) in
        if let sess = session {
            getAuth().session = sess
            SPTAudioStreamingController.sharedInstance().login(withAccessToken: sess.accessToken)
            authorizeSpotifyAccess()
        }
    }
    private static var isLoggedIn = false
    
    override init() {
        super.init()
        SPTAudioStreamingController.sharedInstance().delegate = self
    }
    
    // MARK: - Authorization
    
    static func getAuth() -> SPTAuth {
        let auth = SPTAuth.defaultInstance()
        auth?.clientID = SpotifyConstants.clientID
        auth?.redirectURL = SpotifyConstants.redirectURL
        auth?.tokenSwapURL = SpotifyConstants.swapURL
        auth?.tokenRefreshURL = SpotifyConstants.refreshURL
        
        auth?.requestedScopes = [SPTAuthStreamingScope]
        auth?.sessionUserDefaultsKey = "current session"
        
        return auth!
    }
    
    func requestAuthorization() {
        let auth = SpotifyAuthorizationManager.getAuth()
        try? SPTAudioStreamingController.sharedInstance().start(withClientId: auth.clientID)
        
        DispatchQueue.main.async {
            SpotifyAuthorizationManager.startAuthenticationFlow(usingAuth: auth)
        }
    }
    
    private static func startAuthenticationFlow(usingAuth auth: SPTAuth, doRenew: Bool = false) {
        if auth.session == nil {
            promptLoginScreen(usingAuth: auth)
        } else if auth.session.isValid() && !doRenew {
            login(usingSession: auth.session)
        } else {
            renew(usingAuth: auth)
        }
    }
    
    private static func promptLoginScreen(usingAuth auth: SPTAuth) {
        let authURL = auth.spotifyWebAuthenticationURL()
        
        authViewController = SFSafariViewController(url: authURL!)
        delegate?.present(authViewController, animated: true, completion: nil)
    }
    
    private static func login(usingSession session: SPTSession) {
        delegate?.processingLogin = true
        SPTAudioStreamingController.sharedInstance().login(withAccessToken: session.accessToken)
        
        authorizeSpotifyAccess()
    }
    
    private static func renew(usingAuth auth: SPTAuth) {
        delegate?.processingLogin = true
        auth.renewSession(auth.session, callback: updateSession)
    }
    
    static func authorizeSpotifyAccess() {
        let request = SpotifyURLFactory.createAccessTokenRequest()
        
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = JSON(data: data!)
                    Party.cookie = json["access_token"].stringValue
                    DispatchQueue.main.async {
                        guard delegate != nil else { return }
                        if isLoggedIn && delegate!.processingLogin {
                            delegate?.processingLogin = false
                            delegate?.performSegue(withIdentifier: "Create Party", sender: nil)
                        }
                    }
                } else {
                    postAlertForInternet()
                    delegate?.processingLogin = false
                }
            }
            
            task.resume()
        }
    }
    
    // MARK: - Callbacks
    
    @objc static func createSession(withNotification notification: NSNotification) {
        let url = notification.object as! URL
        let auth = getAuth()
        
        if auth.canHandle(url) {
            authViewController.dismiss(animated: true, completion: nil)
            delegate?.processingLogin = true
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: updateSession)
        }
    }
    
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        SpotifyAuthorizationManager.isLoggedIn = true
        DispatchQueue.main.async {
            guard SpotifyAuthorizationManager.delegate != nil else { return }
            if Party.cookie != nil && SpotifyAuthorizationManager.delegate!.processingLogin {
                SpotifyAuthorizationManager.delegate?.processingLogin = false
                SpotifyAuthorizationManager.delegate?.performSegue(withIdentifier: "Create Party", sender: nil)
            }
        }
    }
    
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didReceiveError error: Error!) {
        SpotifyAuthorizationManager.postAlertForSpotifyPremium()
        SpotifyAuthorizationManager.delegate?.processingLogin = false
        SpotifyAuthorizationManager.getAuth().session = nil
    }
    
    // MARK: - Alerts
    
    private static func postAlertForInternet() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Please check your internet connection", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
                delegate?.createParty()
            })
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            
            delegate?.present(alert, animated: true, completion: nil)
        }
    }
    
    private static func postAlertForSpotifyPremium() {
        let alert = UIAlertController(title: "No Spotify Premium", message: "A Spotify Premium account is required to play music", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        delegate?.present(alert, animated: true, completion: nil)
    }
}
