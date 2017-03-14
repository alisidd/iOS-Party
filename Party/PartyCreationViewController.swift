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
            spotifyButton.backgroundColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 0.5)
        }
    }
    @IBOutlet weak var partyNameField: UITextField! {
        didSet {
            partyNameField.delegate = self
        }
    }
    @IBOutlet weak var danceabilityView: UIView! {
        didSet {
            danceabilityView.makeBorder()
        }
    }
    
    // MARK: - General Variables
    
    private var partyMade = Party()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addBlurToBackground()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        customizeNavigationBar()
        customizeTextField()
    }
    
    // MARK: - Functions
    
    func addBlurToBackground() {
        backgroundImageView.addBlur(withAlpha: 1)
        spotifyButton.subviews[0].removeFromSuperview()
    }
    
    func customizeNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
        navigationController?.navigationBar.tintColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white, NSFontAttributeName: UIFont(name: "Helvetica Light", size: 20)!]
    }
    
    @IBAction func changeToAppleMusic(_ sender: setupButton) {
        if partyMade.musicService == .spotify {
            UIView.animate(withDuration: 0.25, animations: {
                sender.backgroundColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 0.5)
                self.spotifyButton.backgroundColor = UIColor.clear
                self.appleMusicButton.subviews[0].removeFromSuperview()
                self.spotifyButton.addBlur(withAlpha: 0.6)
            })
            partyMade.musicService = .appleMusic
        }
    }
    
    @IBAction func changeToSpotify(_ sender: setupButton) {
        if partyMade.musicService == .appleMusic {
            UIView.animate(withDuration: 0.25, animations: {
                sender.backgroundColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 0.5)
                self.appleMusicButton.backgroundColor = UIColor.clear
                self.spotifyButton.subviews[0].removeFromSuperview()
                self.appleMusicButton.addBlur(withAlpha: 0.6)
            })
            partyMade.musicService = .spotify
        }
    }
    
    func customizeTextField() {
        partyNameField.backgroundColor = UIColor.clear
        partyNameField.attributedPlaceholder = NSAttributedString(string: "Party Name", attributes: [NSForegroundColorAttributeName: UIColor.white])
        addBorder()
        partyNameField.autocapitalizationType = UITextAutocapitalizationType.sentences
        partyNameField.returnKeyType = .done
    }
    
    func addBorder() {
        let border = CALayer()
        let width = CGFloat(2.0)
        border.borderColor = UIColor(red: 1, green: 147/255, blue: 0, alpha: 1).cgColor 
        border.frame = CGRect(x: 0, y: (0.9 * partyNameField.frame.size.height) - width, width: partyNameField.frame.size.width, height: 1)
        
        border.borderWidth = 0.5
        partyNameField.layer.addSublayer(border)
        partyNameField.layer.masksToBounds = true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "\n" {
            partyNameField.resignFirstResponder()
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        partyNameField.resignFirstResponder()
    }
    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let text = partyNameField.text {
            partyMade.partyName = text
        }
        
        if partyMade.partyName.isEmpty && identifier == "Create Party" {
            alertUser()
            return false
        } else {
            return true
        }
    }
    
    func alertUser() {
        let alert = UIAlertController(title: "No Party Name", message: "You have to provide a party name to continue", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Create Party" {
            if let controller = segue.destination as? PartyViewController {
                controller.party = partyMade
                controller.tracksListManager.partyName = partyMade.partyName
                controller.tracksListManager.delegate = controller
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        }
    }

}
