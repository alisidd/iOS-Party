//
//  AddSongViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class AddSongViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var searchSongsField: UITextField!
    
    var party = Party()
    private var songsList = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundImageView()
        customizeNavigationBar()
        self.searchSongsField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customizeTextField()
    }
    
    func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
    }
    
    func customizeNavigationBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(AddSongViewController.goBack))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        
        self.navigationItem.setHidesBackButton(true, animated: false)
    }
    
    func customizeTextField() {
        searchSongsField.attributedPlaceholder = NSAttributedString(string: "Search Songs", attributes: [NSForegroundColorAttributeName: UIColor.lightGray])
        searchSongsField.layer.borderWidth = 1.5
        
        searchSongsField.autocapitalizationType = UITextAutocapitalizationType.sentences
    }
    
    func textFieldShouldReturn(_ searchSongsField: UITextField) -> Bool {
        searchSongsField.resignFirstResponder()
        if !(searchSongsField.text?.isEmpty)! {
            fetchResults(forQuery: searchSongsField.text!)
        }
        return true
    }
    
    func fetchResults(forQuery query: String) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    func goBack() {
        _ = navigationController?.popViewController(animated: true)
    }

}
