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
            loginToPlayer(withAccessToken: sess.accessToken)
        }
    }
    static var storyboardSegue: String!
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
        auth?.requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistReadPrivateScope, SPTAuthUserLibraryReadScope]
        auth?.sessionUserDefaultsKey = "local session"
        
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
        loginToPlayer(withAccessToken: session.accessToken)
    }
    
    private static func renew(usingAuth auth: SPTAuth) {
        delegate?.processingLogin = true
        auth.renewSession(auth.session, callback: updateSession)
    }
    
    private static func loginToPlayer(withAccessToken accessToken: String) {
        if Party.cookie == nil {
            SPTAudioStreamingController.sharedInstance().login(withAccessToken: accessToken)
        } else {
            completeAuthorization()
        }
    }
    
    private static func completeAuthorization() {
        DispatchQueue.main.async {
            delegate?.performSegue(withIdentifier: storyboardSegue, sender: nil)
        }
        delegate?.processingLogin = false
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
        Party.cookie = SpotifyAuthorizationManager.getAuth().session.accessToken
        DispatchQueue.main.async {
            guard SpotifyAuthorizationManager.delegate != nil else { return }
            if Party.cookie != nil && SpotifyAuthorizationManager.delegate!.processingLogin {
                SpotifyAuthorizationManager.delegate?.processingLogin = false
                SpotifyAuthorizationManager.delegate?.performSegue(withIdentifier: SpotifyAuthorizationManager.storyboardSegue, sender: nil)
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
            let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("Please check your internet connection", comment: ""), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: ""), style: .default) { _ in
                delegate?.tryAgain()
            })
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
            
            delegate?.present(alert, animated: true, completion: nil)
        }
    }
    
    private static func postAlertForSpotifyPremium() {
        let alert = UIAlertController(title: NSLocalizedString("No Spotify Premium", comment: ""), message: NSLocalizedString("A Spotify Premium account is required to play music", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
        
        delegate?.present(alert, animated: true, completion: nil)
    }
    
}
