//
//  PartiesListViewController.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/24/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

protocol PartiesListerDelegate: class {
    func reloadList()
}

class PartiesListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PartiesListerDelegate {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var activityIndicator: NVActivityIndicatorView?
    @IBOutlet weak var partiesListTableView: UITableView!
    
    var networkManager: MultipeerManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeActivityIndicator()
        setDelegates()
        adjustFontSizes()
    }
    
    private func setDelegates() {
        partiesListTableView.delegate = self
        partiesListTableView.dataSource = self
        reloadList()
    }
    
    private func adjustFontSizes() {
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            titleLabel.changeToSmallerFont()
        }
    }
    
    private func initializeActivityIndicator() {
        activityIndicator?.startAnimating()
    }
    
    func reloadList() {
        DispatchQueue.main.async { [weak self] in
            guard self != nil && self!.networkManager != nil else { return }
            if self!.networkManager.allHosts.isEmpty {
                self?.activityIndicator?.startAnimating()
            } else {
                self?.activityIndicator?.stopAnimating()
            }
            self?.partiesListTableView?.reloadData()
        }
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return networkManager.allHosts.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Party Cell", for: indexPath) as! OptionTableViewCell

        // Cell Properties
        cell.optionName.text = networkManager.allHosts[indexPath.row].partyName
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedHost = networkManager.allHosts[indexPath.row]
        
        performSegue(withIdentifier: "Join Party", sender: selectedHost.partyName)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.networkManager.invite(peerID: selectedHost.hostID, forFirstTime: true)
            self?.networkManager = nil
        }
    }
    

    // MARK: - Navigation

    @IBAction func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let partyName = sender as? String, let controller = segue.destination as? PartyViewController {
            Party.name = partyName
            
            controller.isHost = false
            controller.networkManager = networkManager
            controller.networkManager?.delegate = controller
            Party.delegate = controller
        }
    }

}
