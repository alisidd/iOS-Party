//
//  LyricsAndQueuePageViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 3/15/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class HubAndQueuePageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var party = Party()
    weak var partyDelegate: PartyViewControllerInfoDelegate?
    var allViewControllers = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegates()
        populateListOfViewControllers()
    }
    
    func setDelegates() {
        self.delegate = self
        self.dataSource = self
    }
    
    func populateListOfViewControllers() {
        let hubViewController = storyboard!.instantiateViewController(withIdentifier: "Hub")
        let tracksQueueViewController = storyboard!.instantiateViewController(withIdentifier: "Queue")
        
        allViewControllers.append(hubViewController)
        allViewControllers.append(tracksQueueViewController)
        
        let vc1 = allViewControllers[0] as! HubViewController
        vc1.delegate = partyDelegate!
        
        let vc2 = allViewControllers[1] as! QueueViewController
        vc2.party = party
        vc2.delegate = partyDelegate!
        
        setViewControllers([tracksQueueViewController], direction: .reverse, animated: true, completion: nil)
    }
    
    func updateTable() {
        if let vc = allViewControllers[1] as? QueueViewController {
            vc.party = party
            vc.updateTable()
        }
    }
    
    func expandTracksTable() {
        if let vc = allViewControllers[1] as? QueueViewController {
            vc.makeTracksTableTaller()
        }
    }
    
    func minimizeTracksTable() {
        if let vc = allViewControllers[1] as? QueueViewController {
            vc.makeTracksTableShorter()
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = allViewControllers.index(of: viewController)
        if index == 0 {
            return nil
        } else {
            return allViewControllers[0]
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = allViewControllers.index(of: viewController)
        if index == 1 {
            return nil
        } else {
            return allViewControllers[1]
        }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return allViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 1
    }

}
