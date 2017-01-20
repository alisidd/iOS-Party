//
//  PartyViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 1/19/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

protocol updateTracksQueue: class {
    func updateTracksQueue(withQueue queue: [Track])
    func tracksQueue(hasTrack track: Track) -> Bool
}

class PartyViewController: UIViewController, updateTracksQueue {
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    
    private var party = Party()
    private var tracksQueue = [Track]() {
        didSet {
            print(tracksQueue)
        }
    }
    
    func initializeVariables(withParty partyMade: Party) {
        party.partyName = partyMade.partyName
        party.musicService = partyMade.musicService
        party.genres = partyMade.genres
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        blurBackgroundImageView()
        setupNavigationBar()
    }
    
    private func blurBackgroundImageView() {
        let blurEffect: UIBlurEffect = UIBlurEffect(style: UIBlurEffectStyle.dark)
        
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = backgroundImageView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.addSubview(blurView)
    }
    
    private func setupNavigationBar() {
        self.title = party.partyName
    }
    
    func updateTracksQueue(withQueue queue: [Track]) {
        tracksQueue = queue
    }
    
    func tracksQueue(hasTrack track: Track) -> Bool {
        for trackInQueue in tracksQueue {
            if track.id == trackInQueue.id {
                return true
            }
        }
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Songs" {
            if let controller = segue.destination as? AddSongViewController {
                self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
                controller.party = party
                controller.delegate = self
            }
        }
        
    }
    

}
