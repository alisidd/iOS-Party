//
//  SpotifyAuthorizationManager.swift
//  WeJ
//
//  Created by Ali Siddiqui on 7/26/17.
//  Copyright © 2017 Ali Siddiqui. All rights reserved.
//

import Foundation

class SpotifyAuthorizationManager: AuthorizationManager {
    static weak var delegate: ViewControllerAccess?
    
    private static var authViewController: SFSafariViewController?
    var isAuthorized = false
        
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
    
    private static let updateSession: (Error?, SPTSession?) -> Void = { (_, session) in
        if let sess = session {
            getAuth().session = sess
            delegate?.performSegue(withIdentifier: "Create Party", sender: nil)
        }
        delegate?.processingLogin = false
    }
    
    private static func startAuthenticationFlow(usingAuth auth: SPTAuth) {
        if auth.session == nil {
            promptLoginScreen(usingAuth: auth)
        } else if auth.session.isValid() {
            login(usingSession: auth.session)
        } else {
            renew(usingAuth: auth)
        }
    }
    
    private static func promptLoginScreen(usingAuth auth: SPTAuth) {
        let authURL = auth.spotifyWebAuthenticationURL()
        
        authViewController = SFSafariViewController(url: authURL!)
        delegate?.present(authViewController!, animated: true, completion: nil)
    }
    
    private static func login(usingSession session: SPTSession) {
        SPTAudioStreamingController.sharedInstance().login(withAccessToken: session.accessToken)
        delegate?.performSegue(withIdentifier: "Create Party", sender: nil)
        print(session.expirationDate.timeIntervalSinceNow)
    }
    
    private static func renew(usingAuth auth: SPTAuth) {
        delegate?.processingLogin = true
        auth.renewSession(auth.session, callback: updateSession)
    }
    
    //MARK: - Callbacks
    
    @objc static func createSession(withNotification notification: NSNotification) {
        let url = notification.object as! URL
        let auth = getAuth()
        
        if auth.canHandle(url) {
            authViewController?.dismiss(animated: true, completion: nil)
            delegate?.processingLogin = true
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: updateSession)
        }
    }
}
