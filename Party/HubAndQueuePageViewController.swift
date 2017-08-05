//
//  LyricsAndQueuePageViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 3/15/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class HubAndQueuePageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    weak var partyDelegate: PartyViewControllerInfoDelegate?
    private var allViewControllers = [UIViewController]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegates()
        populateListOfViewControllers()
    }
    
    private func setDelegates() {
        delegate = self
        dataSource = self
    }
    
    private func populateListOfViewControllers() {
        let hubViewController = storyboard!.instantiateViewController(withIdentifier: "Hub")
        let tracksQueueViewController = storyboard!.instantiateViewController(withIdentifier: "Queue")
        
        allViewControllers.append(hubViewController)
        allViewControllers.append(tracksQueueViewController)
        
        let vc1 = allViewControllers[0] as! HubViewController
        vc1.delegate = partyDelegate!
        
        let vc2 = allViewControllers[1] as! QueueViewController
        vc2.delegate = partyDelegate!
        
        setViewControllers([tracksQueueViewController], direction: .reverse, animated: true, completion: nil)
    }
    
    func updateHubTitle() {
        if let vc = allViewControllers[0] as? HubViewController {
            vc.updateHubTitle()
        }
    }
    
    func updateTable() {
        if let vc = allViewControllers[1] as? QueueViewController {
            vc.updateTable()
        }
    }
    
    func showAddButton() {
        if let vc = allViewControllers[1] as? QueueViewController {
            vc.showAddButton()
        }
    }
    
    func hideAddButton() {
        if let vc = allViewControllers[1] as? QueueViewController {
            vc.hideAddButton()
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
        return index == 0 ? nil : allViewControllers[0]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index = allViewControllers.index(of: viewController)
        return index == 1 ? nil : allViewControllers[1]
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return allViewControllers.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 1
    }

}
