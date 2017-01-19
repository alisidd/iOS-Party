//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

enum MusicService {
    case appleMusic
    case spotify
}

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, changeSelectedGenresList {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var appleMusicButton: setupButton!
    @IBOutlet weak var spotifyButton: setupButton!
    @IBOutlet weak var partyNameField: UITextField!
    @IBOutlet weak var selectGenresButton: setupButton!
    
    private var musicService = MusicService.appleMusic
    private var selectedGenres = [String]()
    
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
        musicService = .appleMusic
    }
    
    @IBAction func changeToSpotify(_ sender: setupButton) {
        UIView.animate(withDuration: 0.25, animations: {
            sender.backgroundColor = UIColor(colorLiteralRed: 15/255, green: 15/255, blue: 15/255, alpha: 1)
            self.appleMusicButton.backgroundColor = UIColor(colorLiteralRed: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        })
        musicService = .spotify
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
    
    func addToGenresList(withGenre genre: String) {
        selectedGenres.append(genre)
    }
    
    func removeFromGenresList(withGenre genre: String) {
        selectedGenres.remove(at: selectedGenres.index(of: genre)!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if (self.partyNameField.text?.isEmpty)! {
            alertUser()
            return false
        } else {
            return true
        }
    }
    
    func alertUser() {
        let alert = UIAlertController(title: "No Party Name", message: "You have to provide a party name to continue", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Genre Popover" {
            if let controller = segue.destination as? GenrePickingTableViewController {
                controller.delegate = self
                controller.selectedGenres = selectedGenres
            }
        } else if segue.identifier == "Create Party" {
            if let controller = segue.destination as? PartyViewController {
                controller.selectedGenres = selectedGenres
                controller.musicService = musicService
                controller.partyName = self.partyNameField.text!
            }
        }
    }

}
