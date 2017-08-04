//
//  SpotifyAuthorizationManager.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/26/17.
//  Copyright © 2017 Ali Siddiqui. All rights reserved.
//

import Foundation
import SafariServices
import SwiftyJSON

class SpotifyAuthorizationManager: AuthorizationManager {
    static weak var delegate: ViewControllerAccessDelegate!
    
    private static var authViewController: SFSafariViewController!
    var isAuthorized = false
    
    private static let updateSession: (Error?, SPTSession?) -> Void = { (_, session) in
        if let sess = session {
            getAuth().session = sess
            
            authorizeSpotifyAccess()
            dispatchGroup.wait()
            
            delegate.performSegue(withIdentifier: "Create Party", sender: nil)
        }
        delegate.processingLogin = false
    }
    static let dispatchGroup = DispatchGroup()
    
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
        delegate.present(authViewController, animated: true, completion: nil)
    }
    
    private static func login(usingSession session: SPTSession) {
        delegate.processingLogin = true
        SPTAudioStreamingController.sharedInstance().login(withAccessToken: session.accessToken)
        
        authorizeSpotifyAccess()
        dispatchGroup.wait()
        
        delegate.processingLogin = false
        delegate.performSegue(withIdentifier: "Create Party", sender: nil)
    }
    
    private static func renew(usingAuth auth: SPTAuth) {
        delegate.processingLogin = true
        auth.renewSession(auth.session, callback: updateSession)
    }
    
    static func authorizeSpotifyAccess() {
        let request = SpotifyURLFactory.createAccessTokenRequest()
        
        dispatchGroup.enter()
        DispatchQueue.global(qos: .userInitiated).async {
            let task = URLSession.shared.dataTask(with: request) { (data, response, _) in
                if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 {
                    let json = JSON(data: data!)
                    Party.cookie = json["access_token"].stringValue
                }
                dispatchGroup.leave()
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
            delegate.processingLogin = true
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: updateSession)
        }
    }
}
