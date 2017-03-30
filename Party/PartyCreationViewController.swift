//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

protocol AppleMusicAuthorizationAlertDelegate: class {
    func postAlertForSettings()
    func postAlertForNoAppleMusic()
}

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, AppleMusicAuthorizationAlertDelegate {
    
    // MARK: - Storyboard Variables
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var appleMusicButton: setupButton!
    @IBOutlet weak var spotifyButton: setupButton! {
        didSet {
            spotifyButton.makeBorder()
        }
    }
    @IBOutlet weak var danceabilitySlider: UISlider! {
        didSet {
            customizeSliderImage()
        }
    }
    
    // MARK: - General Variables
    
    private var partyMade = Party()
    var musicPlayer = MusicPlayer()
    let APIManager = RestApiManager()
    var authViewController: SFSafariViewController?
    var spotifySession: SPTSession?

    let primaryColor = UIColor.white.withAlphaComponent(1)
    let secondaryColor = UIColor(red: 203/255, green: 199/255, blue: 199/255, alpha: 0.5)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeNavigationBarTransparent()
        setDelegates()
    }
    
    func customizeSliderImage() {
        danceabilitySlider.setThumbImage(#imageLiteral(resourceName: "thumbSlider"), for: .normal)
        danceabilitySlider.setThumbImage(#imageLiteral(resourceName: "thumbSlider"), for: .highlighted)
    }
    
    func makeNavigationBarTransparent() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
    }
    
    func setDelegates() {
        musicPlayer.delegate = self
    }
    
    // MARK: - Functions
    
    @IBAction func changeToAppleMusic(_ sender: setupButton) {
        if partyMade.musicService == .spotify {
            UIView.animate(withDuration: 0.5) {
                self.selectButton(for: .appleMusic)
            }
            partyMade.musicService = .appleMusic
        }
    }
    
    @IBAction func changeToSpotify(_ sender: setupButton) {
        if partyMade.musicService == .appleMusic {
            UIView.animate(withDuration: 0.5) {
                self.selectButton(for: .spotify)
            }
            partyMade.musicService = .spotify
        }
    }
    
    func selectButton(for service: MusicService) {
        if service == .spotify {
            spotifyButton.makeBorder()
            appleMusicButton.removeBorder()
            
            spotifyButton.titleLabel?.textColor = primaryColor
            appleMusicButton.titleLabel?.textColor = secondaryColor
        } else {
            appleMusicButton.makeBorder()
            spotifyButton.removeBorder()
            
            appleMusicButton.titleLabel?.textColor = primaryColor
            spotifyButton.titleLabel?.textColor = secondaryColor
        }
    }
    
    @IBAction func initializeMusicPlayer(_ sender: UIButton) {
        musicPlayer.party = partyMade
        
        if partyMade.musicService == .appleMusic {
            authorizeAppleMusic()
            musicPlayer.authorizationDispatchGroup.wait()
            if musicPlayer.isAuthorized {
                performSegue(withIdentifier: "Create Party", sender: nil)
            }
        } else {
            authorizeSpotify()
        }
    }
    
    // MARK: - Apple Music Authorization
    
    func authorizeAppleMusic() {
        musicPlayer.hasCapabilities()
        musicPlayer.haveAuthorization()
    }
    
    func postAlertForSettings() {
        let alert = UIAlertController(title: "Apple Music Access Denied", message: "Go to settings to enable Apple Music for this app", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { (alert: UIAlertAction!) in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        })
        
        present(alert, animated: true)
    }
    
    func postAlertForNoAppleMusic() {
        let alert = UIAlertController(title: "No Apple Music Subscription", message: "You need to have an Apple Music subscription for this option", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    // MARK: - Spotify Authorization
    
    func authorizeSpotify() {
        let auth = APIManager.getAuthentication()
        
        do {
            try musicPlayer.spotifyPlayer?.start(withClientId: auth?.clientID)
            DispatchQueue.main.async {
                self.startAuthenticationFlow(auth!)
            }
        } catch {
            if musicPlayer.spotifyPlayer!.initialized {
                self.performSegue(withIdentifier: "Create Party", sender: nil)
            } else {
                print("Error starting Spotify Player")
            }
        }
    }
    
    private func startAuthenticationFlow(_ authentication: SPTAuth) {
        let authURL = authentication.spotifyWebAuthenticationURL()
        
        NotificationCenter.default.addObserver(self, selector: #selector(spotifyLogin(notification:)), name: NSNotification.Name(rawValue: "authViewControllerNotification"), object: nil)
        
        authViewController = SFSafariViewController(url: authURL!)
        present(authViewController!, animated: true)
    }
    
    @objc private func spotifyLogin(notification: NSNotification) {
        let url = notification.object as! URL
        
        let auth = APIManager.getAuthentication()
        
        if auth!.canHandle(url) {
            authViewController?.dismiss(animated: true, completion: nil)
            auth?.handleAuthCallback(withTriggeredAuthURL: url, callback: { (error, session) in
                self.spotifySession = session
                let userDefaults = UserDefaults.standard
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session!)
                userDefaults.set(sessionData, forKey: "SpotifySession")
                userDefaults.synchronize()
                self.performSegue(withIdentifier: "Create Party", sender: nil)
            })
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        partyMade.danceability = sender.value
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Create Party" {
            if let controller = segue.destination as? PartyViewController {
                controller.party = partyMade
                controller.musicPlayer = musicPlayer
                
                if partyMade.musicService == .spotify {
                    controller.spotifySession = spotifySession
                }
                
                controller.tracksListManager?.partyName = "Placeholder Party Name"
                controller.tracksListManager?.delegate = controller
            }
        }
    }
}
