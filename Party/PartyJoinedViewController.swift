//
//  PartyJoinedViewController.swift
//  Party
//
//  Created by Matthew on 2016-11-14.
//  Copyright © 2016 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class PartyJoinedViewController: UITableViewController {

    var localParties = [Party]()
    let partiesListManager = NetworkServiceManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        partiesListManager.delegate = self
        // Will browse as device name
        partiesListManager.isHost = false // Only browse, don't advertise
        
        
        // Add a background view to the table view
        let imageView = UIImageView(image: #imageLiteral(resourceName: "background"))
        self.tableView.backgroundView = imageView
        
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        
        blurBackgroundImageView()
        customizeNavigationBar()
                
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        blurView.frame = (self.tableView.backgroundView?.bounds)!
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.tableView.backgroundView?.addSubview(blurView)
    }

    // MARK: - Table view data source

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
        cell.partyNameLabel.text = party.partyName
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
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}

// MARK: NetworkManagerDelegate

extension PartyJoinedViewController: NetworkManagerDelegate {
    
    func connectedDevicesChanged(_ manager: NetworkServiceManager, connectedDevices: [String]) {
        OperationQueue.main.addOperation { () -> Void in
            print("Connections: \(connectedDevices)")
        }
    }
    
    func messageChanged(_ manager: NetworkServiceManager, messageString: String) {
        OperationQueue.main.addOperation { () -> Void in
            print(messageString)
        }
    }
    
}

