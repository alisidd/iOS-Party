//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

protocol ChangeSelectedGenresListDelegate: class {
    func addToGenresList(withGenre genre: String)
    func removeFromGenresList(withGenre genre: String)
}

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, ChangeSelectedGenresListDelegate {
    
    // MARK: - Storyboard Variables
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var appleMusicButton: setupButton!
    @IBOutlet weak var spotifyButton: setupButton!
    @IBOutlet weak var partyNameField: UITextField!
    @IBOutlet weak var selectGenresButton: setupButton!
    
    // MARK: - General Variables
    
    private var partyMade = Party()
    
    // MARK: - Lifecycle
    
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
    
    // MARK: - Functions
    
    func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
    }
    
    func customizeNavigationBar() {
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
        
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.systemFont(ofSize: 20), NSForegroundColorAttributeName: UIColor.white]
    }
    
    @IBAction func changeToAppleMusic(_ sender: setupButton) {
        UIView.animate(withDuration: 0.25, animations: {
            sender.backgroundColor = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
            self.spotifyButton.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        })
        partyMade.musicService = .appleMusic
    }
    
    @IBAction func changeToSpotify(_ sender: setupButton) {
        UIView.animate(withDuration: 0.25, animations: {
            sender.backgroundColor = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
            self.appleMusicButton.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        })
        partyMade.musicService = .spotify
    }
    
    func initializeTextField() {
        partyNameField.delegate = self
    }
    
    func customizeTextField() {
        partyNameField.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 37/255)
        partyNameField.attributedPlaceholder = NSAttributedString(string: "Party Name", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        partyNameField.autocapitalizationType = UITextAutocapitalizationType.sentences
        partyNameField.returnKeyType = .done
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
    
    func addToGenresList(withGenre genre: String) {
        partyMade.genres.append(genre)
    }
    
    func removeFromGenresList(withGenre genre: String) {
        partyMade.genres.remove(at: partyMade.genres.index(of: genre)!)
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
        if segue.identifier == "Genre Popover" {
            if let controller = segue.destination as? GenrePickingViewController {
                controller.delegate = self
                controller.party = partyMade
            }
        } else if segue.identifier == "Create Party" {
            if let controller = segue.destination as? PartyViewController {
                controller.party = partyMade
                controller.tracksListManager.partyName = partyMade.partyName
                controller.tracksListManager.delegate = controller
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        }
    }

}
