//
//  PartyJoinedViewController.swift
//  Party
//
//  Created by Matthew on 2016-11-14.
//  Copyright © 2016 Ali Siddiqui and Matthew Paletta. All rights reserved.
//

import UIKit

class PartyJoinedViewController: UITableViewController {
    
    // MARK: - General Variables

    var localParties = [Party]()
    //let partiesListManager = NetworkServiceManager()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //partiesListManager.delegate = self
        // Will browse as device name
        
        
        // Add a background view to the table view
        let imageView = UIImageView(image: #imageLiteral(resourceName: "background"))
        self.tableView.backgroundView = imageView
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        blurBackgroundImageView()
        customizeNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName : UIFont.systemFont(ofSize: 20), NSForegroundColorAttributeName: UIColor.white]
    }
    
    // MARK: - Functions
    
    func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = (self.tableView.backgroundView?.bounds)!
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tableView.backgroundView?.addSubview(blurView)
    }
    
    func customizeNavigationBar() {
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.view.backgroundColor = UIColor.clear
    }
    
    

    // MARK: - Table

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return localParties.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "partyListCell", for: indexPath) as! PartyListCell
        
        // Fetches the appropriate party for the data source layout.
        let party = localParties[(indexPath as NSIndexPath).row]
        

        // Configure the cell...
        if let _ = party.password {
            cell.isLockedImage.image = #imageLiteral(resourceName: "locked")
        } else {
            cell.isLockedImage.image = #imageLiteral(resourceName: "unlocked")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let party = localParties[(indexPath.row)]
        let cell = tableView.dequeueReusableCell(withIdentifier: "partyListCell", for: indexPath) as! PartyListCell
        
        if party.isLocked && cell.passwordField.text == "" {
            // prompt for password
            UIView.animate(withDuration: 0.3) {
                cell.passwordField.isHidden = false
            }
        } else if party.isLocked && cell.passwordField.text != party.password {
            // incorrect password, prompt
            
            let alertController = UIAlertController(title: "Party", message: "Incorrect Password", preferredStyle: UIAlertControllerStyle.alert)
            present(alertController, animated: true, completion: nil)
            cell.passwordField.text = ""
            
        } else {
            // start segue
            self.performSegue(withIdentifier: "showParty", sender: nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "partyListCell", for: indexPath) as! PartyListCell
        if !cell.passwordField.isHidden { // if its not hidden and selected something else, hide the field again.
            UIView.animate(withDuration: 0.3) {
                cell.passwordField.isHidden = true
            }
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Go To Party" {
            if let destinationVC = segue.destination as? PartyViewController {
                print("Setting isHost to false")
                destinationVC.isHost = false
                destinationVC.tracksListManager?.delegate = destinationVC
                navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        }
    }
}

// MARK: - NetworkManagerDelegate
/*
extension PartyJoinedViewController: NetworkManagerDelegate {
    
    func connectedDevicesChanged(_ manager: NetworkServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }
    
    func addTracksFromPeer(withTracks tracks: [String]) {
        // Add here
    }
    
}*/

