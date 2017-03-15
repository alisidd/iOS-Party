//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate {
    
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
    let primaryColor = UIColor.white.withAlphaComponent(1)
    let secondaryColor = UIColor(red: 203/255, green: 199/255, blue: 199/255, alpha: 0.5)
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        makeNavigationBarTransparent()
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
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Create Party" {
            if let controller = segue.destination as? PartyViewController {
                controller.party = partyMade
                controller.tracksListManager.partyName = "Placeholder Party Name"
                controller.tracksListManager.delegate = controller
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        }
    }

}
