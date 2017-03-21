//
//  InitialSetupViewController.swift
//  Party
//
//  Created by Ali Siddiqui and Matthew Paletta on 11/9/16.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

extension UIView {
    func makeBorder() {
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1, green: 166/255, blue: 35/255, alpha: 1).cgColor
        layer.cornerRadius = 30
    }
    
    func removeBorder() {
        layer.borderWidth = 0
    }
}

class InitialSetupViewController: UIViewController {
    
    @IBOutlet weak var createPartyButton: setupButton!
    @IBOutlet weak var joinPartyButton: setupButton!
        
    // MARK: - Lifecycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            self.navigationController?.setNavigationBarHidden(true, animated: animated)
        }
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
        
        if segue.identifier == "Join Party" {
            if let destinationVC = segue.destination as? PartyViewController {
                print("Setting isHost to false")
                destinationVC.isHost = false
                destinationVC.tracksListManager?.delegate = destinationVC
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        }
    }
}

