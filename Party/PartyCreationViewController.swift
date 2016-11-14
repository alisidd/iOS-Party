//
//  PartyCreationViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/10/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class PartyCreationViewController: UIViewController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var partyNameField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        customizeNavigationBar()
        blurBackgroundImageView()
        
        customizeTextField()
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
    
    func customizeTextField() {
        let bottomBorder = CALayer()
        bottomBorder.frame = CGRect(x: 0, y: partyNameField.frame.height, width: partyNameField.frame.width, height: 1)
        bottomBorder.backgroundColor = UIColor.gray.cgColor
        partyNameField.borderStyle = UITextBorderStyle.none
        partyNameField.layer.addSublayer(bottomBorder)
        partyNameField.attributedPlaceholder = NSAttributedString(string: "Party Name", attributes: [NSForegroundColorAttributeName: UIColor.darkGray])
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
