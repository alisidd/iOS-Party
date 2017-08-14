//
//  InitialSetupViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 11/9/16.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class InitialSetupViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var createPartyButton: setupButton!
    @IBOutlet weak var joinPartyButton: setupButton!
    @IBOutlet weak var versionLabel: UILabel!
        
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        populateVersionNumber()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.isHidden = true
    }
    
    private func populateVersionNumber() {
        if let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            versionLabel.text = "Version " + versionNumber
        }
    }
    
    @IBAction func displayEasterEgg(_ sender: UILongPressGestureRecognizer) {
        sender.isEnabled = false
        versionLabel.text = "😎   " + versionLabel.text!
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PartyViewController {
            controller.isHost = false
            controller.networkManager?.delegate = controller
            Party.delegate = controller
        }
    }
    
}
