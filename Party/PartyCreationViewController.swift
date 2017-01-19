//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

extension UIImage{
    func imageScaledToSize(size : CGSize, isOpaque : Bool) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(size, isOpaque, 0.0)
        
        let imageRect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        self.draw(in: imageRect)
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage!
    }
}

class PartyCreationViewController: UIViewController, UITextFieldDelegate, UIPickerViewDelegate {
    
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
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 55, height: 35))
        imageView.image = #imageLiteral(resourceName: "partyNameIcon").imageScaledToSize(size: CGSize(width: imageView.bounds.width - 20, height: imageView.bounds.height), isOpaque: false)
        imageView.contentMode = UIViewContentMode.center
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
