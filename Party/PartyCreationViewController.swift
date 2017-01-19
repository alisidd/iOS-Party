//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate {
    
    enum MusicService {
        case AppleMusic
        case Spotify
    }

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var appleMusicButton: setupButton!
    @IBOutlet weak var spotifyButton: setupButton!
    @IBOutlet weak var partyNameField: UITextField!
    @IBOutlet weak var selectGenresButton: setupButton!
    
    var musicService = MusicService.AppleMusic
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundImageView()
        initializeTextField()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        customizeNavigationBar()
        customizeTextField()
    }
    
    @IBAction func changeToAppleMusic(_ sender: setupButton) {
        UIView.animate(withDuration: 0.25, animations: {
            sender.backgroundColor = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
            self.spotifyButton.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        })
        musicService = .AppleMusic
    }
    
    @IBAction func changeToSpotify(_ sender: setupButton) {
        UIView.animate(withDuration: 0.25, animations: {
            sender.backgroundColor = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
            self.appleMusicButton.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        })
        musicService = .Spotify
    }
    
    func customizeNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
    }
    
    func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
    }
    
    func initializeTextField() {
        partyNameField.delegate = self
    }
    
    func customizeTextField() {
        partyNameField.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 37/255)

        partyNameField.attributedPlaceholder = NSAttributedString(string: "Party Name", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
 
        partyNameField.autocapitalizationType = UITextAutocapitalizationType.sentences
    }
    
    func textFieldShouldReturn(_ partyNameField: UITextField) -> Bool {
        partyNameField.resignFirstResponder()
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        partyNameField.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
