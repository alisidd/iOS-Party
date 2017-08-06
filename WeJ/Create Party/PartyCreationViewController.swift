//
//  PartyCreationViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 11/10/16.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

protocol ViewControllerAccessDelegate: class {
    var processingLogin: Bool { get set }
    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?)
    func performSegue(withIdentifier identifier: String, sender: Any?)
}

class PartyCreationViewController: UIViewController, UITextFieldDelegate, ViewControllerAccessDelegate {
    // MARK: - Storyboard Variables
    
    @IBOutlet weak var partyNameTextField: partyNameTextField!
    @IBOutlet weak var appleMusicButton: setupButton!
    @IBOutlet weak var spotifyButton: setupButton!
    @IBOutlet weak var createButton: UIButton!
    private var activityIndicator: NVActivityIndicatorView!
    
    // MARK: - General Variables
    
    private var networkManager: MultipeerManager? = MultipeerManager(isHost: false)
    var authorizationManager: AuthorizationManager!
    var processingLogin = false {
        didSet {
            DispatchQueue.main.async {
                if self.processingLogin {
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.stopAnimating()
                    self.completeAuthorization()
                }
                self.createButton.isHidden = self.processingLogin
            }
        }
    }
    
    private func completeAuthorization() {
        if Party.musicService == .spotify && Party.cookie == nil {
            postAlertForInternet()
        } else if Party.musicService == .appleMusic {
            if authorizationManager.isAuthorized && Party.cookie != nil {
                performSegue(withIdentifier: "Create Party", sender: nil)
            } else if !authorizationManager.isAuthorized {
                postAlertForSettings()
            } else {
                postAlertForInternet()
            }
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        networkManager = MultipeerManager(isHost: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeNavigationBarTransparent()
        initializeActivityIndicator()
        setDelegates()
        setSpotifyVariables()
        
        setPartyName()
        setMusicService()
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
    
    func initializeActivityIndicator() {
        let rect = CGRect(x: createButton.center.x - 20, y: createButton.center.y - 20, width: 40, height: 40)
        activityIndicator = NVActivityIndicatorView(frame: rect, type: .ballClipRotateMultiple, color: .white, padding: 0)
        view.addSubview(activityIndicator)
    }
    
    func setDelegates() {
        partyNameTextField.delegate = self
        SpotifyAuthorizationManager.delegate = self
        AppleMusicAuthorizationManager.delegate = self
    }
    
    private func setSpotifyVariables() {
        NotificationCenter.default.addObserver(self, selector: #selector(createSession(withNotification:)), name: SpotifyConstants.spotifyPlayerDidLoginNotification, object: nil)
    }
    
    private func setPartyName() {
        if let partyName = UserDefaults.standard.object(forKey: "partyName") as? String {
            partyNameTextField.text = partyName
            Party.name = partyName
        } else {
            setDefaultPartyName()
        }
    }
    
    private func setDefaultPartyName() {
        let partyName = String(UIDevice().userName().characters.prefix(14)) + " Party"
        partyNameTextField.text = partyName
        Party.name = partyName
    }
    
    private func setMusicService() {
        if let rawMusicService = UserDefaults.standard.object(forKey: "musicService") as? String,
            let musicService = MusicService(rawValue: rawMusicService) {
            if musicService == .spotify {
                changeToSpotify()
            } else {
                changeToAppleMusic()
            }
        } else {
            changeToSpotify()
        }
    }
    
    @objc private func createSession(withNotification notification: NSNotification) {
        SpotifyAuthorizationManager.createSession(withNotification: notification)
    }
    
    // MARK: - Text Field
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if !textField.text!.isEmpty {
            Party.name = textField.text!
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = (textField.text ?? "") as NSString
        let newString = currentString.replacingCharacters(in: range, with: string)
        return  newString.characters.count <= 20
    }
    
    // MARK: - Storyboard Functions
    
    @IBAction func changeToSpotify() {
        change(toButton: spotifyButton, fromButton: appleMusicButton)
        Party.musicService = .spotify
    }
    
    @IBAction func changeToAppleMusic() {
        change(toButton: appleMusicButton, fromButton: spotifyButton)
        Party.musicService = .appleMusic
    }
    
    private func change(toButton button: setupButton, fromButton otherButton: setupButton) {
        UIView.animate(withDuration: 0.2) {
            button.makeBorder()
            otherButton.removeBorder()
            
            button.alpha = 1
            otherButton.alpha = 0.6
        }
    }
    
    @IBAction func createParty() {
        if networkManager!.otherHosts.isEmpty {
            if !processingLogin {
                authorizationManager = Party.musicService == .spotify ? SpotifyAuthorizationManager() : AppleMusicAuthorizationManager()
                authorizationManager.requestAuthorization()
            }
        } else {
            postAlertForOtherHosts()
        }
    }
    
    // MARK: - General Authorization
    
    private func postAlertForOtherHosts() {
        let alert = UIAlertController(title: "Another Party in Progress", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            self.createParty()
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func postAlertForInternet() {
        let alert = UIAlertController(title: "Error", message: "Please check your internet connection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default) { _ in
            self.createParty()
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
            controller.networkManager?.delegate = controller
            Party.delegate = controller
            saveCustomization()
        }
    }
    
    private func saveCustomization() {
        UserDefaults.standard.set(Party.name, forKey: "partyName")
        UserDefaults.standard.set(Party.musicService.rawValue, forKey: "musicService")
    }
}
