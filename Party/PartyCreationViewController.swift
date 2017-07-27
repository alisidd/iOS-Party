//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 11/10/16.
//  Copyright © 2016 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

protocol ViewControllerAccessDelegate: class {
    var processingLogin: Bool { get set }
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func performSegue(withIdentifier identifier: String, sender: Any?)
}

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, ViewControllerAccessDelegate {
    // MARK: - Storyboard Variables
    
    @IBOutlet weak var appleMusicButton: setupButton!
    @IBOutlet weak var spotifyButton: setupButton!
    @IBOutlet weak var danceabilitySlider: UISlider!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    // MARK: - General Variables
    
    private var partyMade = Party()
    private var networkManager: NetworkServiceManager? = NetworkServiceManager(isHost: false)
    var authorizationManager: AuthorizationManager!
    var processingLogin = false {
        didSet {
            DispatchQueue.main.async {
                if self.processingLogin {
                    self.indicator.startAnimating()
                } else {
                    self.indicator.stopAnimating()
                }
                self.createButton.isHidden = self.processingLogin
                
                if self.partyMade.musicService == .appleMusic && !self.processingLogin {
                    if self.authorizationManager.isAuthorized {
                        self.performSegue(withIdentifier: "Create Party", sender: nil)
                    } else {
                        self.postAlertForSettings()
                    }
                }
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeNavigationBarTransparent()
        customizeSliderImage()
        setDelegates()
        setSpotifyVariables()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        networkManager = NetworkServiceManager(isHost: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        networkManager = nil
    }
    
    private func makeNavigationBarTransparent() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
    }
    
    private func customizeSliderImage() {
        danceabilitySlider.setThumbImage(#imageLiteral(resourceName: "thumbSlider"), for: .normal)
        danceabilitySlider.setThumbImage(#imageLiteral(resourceName: "thumbSlider"), for: .highlighted)
    }
    
    func setDelegates() {
        SpotifyAuthorizationManager.delegate = self
        AppleMusicAuthorizationManager.delegate = self
    }
    
    private func setSpotifyVariables() {
        spotifyButton.makeBorder()
        NotificationCenter.default.addObserver(self, selector: #selector(createSession(withNotification:)), name: SpotifyConstants.spotifyPlayerDidLoginNotification, object: nil)
    }
    
    @objc private func createSession(withNotification notification: NSNotification) {
        SpotifyAuthorizationManager.createSession(withNotification: notification)
    }
    
    // MARK: - Storyboard Functions
    
    @IBAction func changeToSpotify(_ sender: setupButton) {
        change(toButton: spotifyButton, fromButton: appleMusicButton)
        partyMade.musicService = .spotify
    }
    
    @IBAction func changeToAppleMusic(_ sender: setupButton) {
        change(toButton: appleMusicButton, fromButton: spotifyButton)
        partyMade.musicService = .appleMusic
    }
    
    private func change(toButton button: setupButton, fromButton otherButton: setupButton) {
        UIView.animate(withDuration: 0.2) {
            button.makeBorder()
            otherButton.removeBorder()
            
            button.alpha = 1
            otherButton.alpha = 0.6
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider) {
        partyMade.danceability = sender.value
    }
    
    @IBAction func createParty(_ sender: UIButton) {
        if networkManager!.otherHosts.isEmpty {            
            if !processingLogin {
                authorizationManager = partyMade.musicService == .spotify ? SpotifyAuthorizationManager() : AppleMusicAuthorizationManager()
                authorizationManager.requestAuthorization()
            }
        } else {
            postAlertForOtherHosts(withButton: sender)
        }
    }
    
    // MARK: - General Authorization
    //FIXME: Exit party and create another party
    private func postAlertForOtherHosts(withButton button: UIButton) {
        let alert = UIAlertController(title: "Another Party in Progress", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            self.createParty(button)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    // MARK: - Apple Music Authorization
    
    private func postAlertForSettings() {
        let alert = UIAlertController(title: "Apple Music Access Denied", message: "Go to Settings to enable Apple Music", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PartyViewController, segue.identifier == "Create Party" {
            controller.party = partyMade
            controller.networkManager?.delegate = controller
        }
    }
}
