//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    enum MusicService {
        case AppleMusic
        case Spotify
    }

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var partyNameField: UITextField!
    @IBOutlet weak var partyNameIcon: UIImageView!
    
    var genres = ["--", "Rock", "Pop", "Hip Hop", "Country", "Alternative"]
    var musicService = MusicService.AppleMusic
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundImageView()
        initializeTextField()
        initializeIcon()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        customizeNavigationBar()
        customizeTextField()
    }
    
    @IBAction func musicServiceChange(_ sender: UISegmentedControl) {
        musicService = sender.selectedSegmentIndex == 0 ? .AppleMusic : .Spotify
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
    
    func initializeIcon() {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        imageView.image = #imageLiteral(resourceName: "partyNameIcon")
        partyNameField.leftView = imageView
        partyNameField.leftViewMode = UITextFieldViewMode.always
    }
    
    func customizeTextField() {
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0, y: partyNameField.frame.height, width: partyNameField.frame.width, height: 1)
        bottomBorder.backgroundColor = UIColor.gray.cgColor
        partyNameField.backgroundColor = UIColor(white: 0.7, alpha: 0.2)
        partyNameField.layer.addSublayer(bottomBorder)
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
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach {
            if $0.bounds.height <= 1 {
                $0.backgroundColor = UIColor.gray
            }
        }
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return genres.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return genres[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: genres[row], attributes: [NSForegroundColorAttributeName: UIColor.white])
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
