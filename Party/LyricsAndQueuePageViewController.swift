//
//  LyricsAndQueuePageViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 3/15/17.
//  Copyright © 2017 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class LyricsAndQueuePageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    var party = Party()
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
        let lyricsViewController = storyboard!.instantiateViewController(withIdentifier: "Lyrics")
        let tracksQueueViewController = storyboard!.instantiateViewController(withIdentifier: "Queue")
        
        allViewControllers.append(lyricsViewController)
        allViewControllers.append(tracksQueueViewController)
        
        setViewControllers([tracksQueueViewController], direction: .reverse, animated: true, completion: nil)
    }
    
    func updateTable(withTracks tracks: [Track]) {
        if let vc = allViewControllers[1] as? QueueViewController {
            vc.tracksQueue = tracks
            vc.updateTable()
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
