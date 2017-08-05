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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }
    
    override func viewDidLoad() {
        populateVersionNumber()
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = ""
        navigationItem.backBarButtonItem = backItem
        
        if let controller = segue.destination as? PartyViewController, segue.identifier == "Join Party" {
            controller.isHost = false
            controller.networkManager?.delegate = controller
            Party.delegate = controller
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
    }
}

