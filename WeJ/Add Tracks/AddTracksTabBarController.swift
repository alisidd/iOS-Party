//
//  AddTracksTabBarController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 8/9/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class AddTracksTabBarController: UITabBarController, UITabBarControllerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    var myHubController: MusicLibrarySelectionViewController!
    
    fileprivate let minHeight = 0.46 * UIScreen.main.bounds.height
    fileprivate let maxHeight = -UIApplication.shared.statusBarFrame.height + 7
    
    fileprivate var previousScrollOffset: CGFloat = 0
    
    var libraryTracksSelected = [Track]() {
        didSet {
            updateBadge(to: libraryTracksSelected.count + tracksSelected.count)
        }
    }
    var tracksSelected = [Track]() {
        didSet {
            updateBadge(to: libraryTracksSelected.count + tracksSelected.count)
        }
    }
    
    var tracksList: [Track] {
        if let controller = selectedViewController as? SearchViewController {
            return controller.tracksList
        } else {
            return myHubController.tracksList
        }
    }
    
    private func updateBadge(to count: Int) {
        if let navigationVC = viewControllers?.first(where: { $0 is UINavigationController }) as? UINavigationController {
            if let controller = navigationVC.viewControllers.first(where: { $0 is MusicLibrarySelectionViewController }) as? MusicLibrarySelectionViewController {
                controller.setBadge(to: count)
            }
            
            if let controller = navigationVC.viewControllers.first(where: { $0 is PlaylistSelectionViewController }) as? PlaylistSelectionViewController {
                controller.setBadge(to: count)
            }
            
            if let controller = navigationVC.viewControllers.first(where: { $0 is PlaylistSubcategorySelectionViewController }) as? PlaylistSubcategorySelectionViewController {
                controller.setBadge(to: count)
            }
            
            if let controller = navigationVC.viewControllers.first(where: { $0 is UserTracksViewController }) as? UserTracksViewController {
                controller.setBadge(to: count)
            }
        }
        
        if let controller = viewControllers?.first(where: { $0 is SearchViewController }) as? SearchViewController {
            controller.setBadge(to: count)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
        adjustViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initializeVariables()
    }
    
    private func setDelegates() {
        delegate = self
    }
    
    private func adjustViews() {
        UITabBarItem.appearance().setTitleTextAttributes([
            NSAttributedStringKey.font: UIFont(name: "AvenirNext-Regular", size: 10)!
            ], for: .normal)
    }
    
    private func initializeVariables() {
        if let navigationVC = viewControllers?.first(where: { $0 is UINavigationController }) as? UINavigationController {
            myHubController = navigationVC.viewControllers.first(where: { $0 is MusicLibrarySelectionViewController }) as? MusicLibrarySelectionViewController
        }
    }
    
    // MARK: - Tab Bar Controller
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let navigationVC = viewController as? UINavigationController,
            let controller = navigationVC.viewControllers.first(where: { $0 is MusicLibrarySelectionViewController }) as? MusicLibrarySelectionViewController, controller.tracksTableView != nil {
            controller.tracksTableView.reloadData()
        }
        
        if let controller = viewController as? SearchViewController {
            controller.trackTableView.reloadData()
        }
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tracksList.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        if Party.tracksQueue(hasTrack: tracksList[indexPath.row]) || tracksSelected.contains(where: { $0.id == tracksList[indexPath.row].id }) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        } else {
            cell.accessoryType = .none
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Track", for: indexPath) as! TrackTableViewCell
        
        // Cell Properties
        cell.trackName.text = tracksList[indexPath.row].name
        cell.artistName.text = tracksList[indexPath.row].artist
        cell.artworkImageView.image = tracksList[indexPath.row].lowResArtwork
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        
        addToQueue(track: tracksList[indexPath.row])
        UIView.animate(withDuration: 0.35) {
            cell.accessoryType = .checkmark
        }
    }
    
    private func addToQueue(track: Track) {
        if !Party.tracksQueue(hasTrack: track) && !tracksSelected.contains(track) {
            tracksSelected.append(track)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)!
        removeFromQueue(track: tracksList[indexPath.row])
        
        if !Party.tracksQueue(hasTrack: tracksList[indexPath.row]) {
            UIView.animate(withDuration: 0.35) {
                cell.accessoryType = .none
            }
        }
    }
    
    private func removeFromQueue(track: Track) {
        if let index = tracksSelected.index(where: {$0.id == track.id}) {
            tracksSelected.remove(at: index)
        }
    }

}

extension AddTracksTabBarController {
    
    // Code taken from https://michiganlabs.com/ios/development/2016/05/31/ios-animating-uitableview-header/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollDiff = scrollView.contentOffset.y - previousScrollOffset
        
        let absoluteTop: CGFloat = 0
        
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteTop
        
        var newHeight = myHubController.headerHeightConstraint.constant
        
        if isScrollingDown {
            newHeight = max(maxHeight, myHubController.headerHeightConstraint.constant - abs(scrollDiff))
            if newHeight != myHubController.headerHeightConstraint.constant {
                myHubController.headerHeightConstraint.constant = newHeight
                changeFontSizeForLabel()
                setScrollPosition(forOffset: previousScrollOffset)
            }
            
        } else if isScrollingUp {
            newHeight = min(minHeight, myHubController.headerHeightConstraint.constant + abs(scrollDiff))
            if newHeight != myHubController.headerHeightConstraint.constant && myHubController.tracksTableView.contentOffset.y < 2 {
                myHubController.headerHeightConstraint.constant = newHeight
                changeFontSizeForLabel()
                setScrollPosition(forOffset: previousScrollOffset)
            }
        }
        
        previousScrollOffset = scrollView.contentOffset.y
    }
    
    fileprivate func changeFontSizeForLabel() {
        UIView.transition(with: myHubController.playlistsButton, duration: 0.5, options: .curveEaseIn, animations: {
            self.myHubController.playlistsButton.titleLabel?.font = self.myHubController.playlistsButton.titleLabel?.font.withSize(22 - 2 * (self.myHubController.headerHeightConstraint.constant / self.minHeight))
        }, completion: nil)
    }
    
    private func setScrollPosition(forOffset offset: CGFloat) {
        myHubController.tracksTableView.contentOffset = CGPoint(x: myHubController.tracksTableView.contentOffset.x, y: offset)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidStopScrolling()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidStopScrolling()
        }
    }
    
    func scrollViewDidStopScrolling() {
        let range = maxHeight - minHeight
        let midPoint = minHeight + (range / 2)
        
        
        myHubController.view.layoutIfNeeded()
        if myHubController.headerHeightConstraint.constant > midPoint {
            UIView.animate(withDuration: 0.2, animations: {
                self.myHubController.headerHeightConstraint.constant = self.minHeight
                self.changeFontSizeForLabel()
                self.myHubController.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.myHubController.headerHeightConstraint.constant = self.maxHeight
                self.changeFontSizeForLabel()
                self.myHubController.view.layoutIfNeeded()
            })
        }
    }
    
}
