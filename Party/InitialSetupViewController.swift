//
//  InitialSetupViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 11/9/16.
//  Copyright © 2016 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

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
        
        if let destinationVC = segue.destination as? PartyViewController, segue.identifier == "Join Party" {
            print("Setting isHost to false")
            destinationVC.isHost = false
            destinationVC.networkManager?.delegate = destinationVC
            navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
    }
}

