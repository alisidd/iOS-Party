//
//  LyricsViewController.swift
//  Party
//
//  Created by Ali Siddiqui on 3/15/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class HubViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: PartyViewControllerInfoDelegate?
    
    let hubTitles = ["Lyrics", "Leave Party"]
    @IBOutlet weak var hubTableView: UITableView!
    @IBOutlet weak var hubLabel: UILabel!
    
    let minHeight: CGFloat = 351
    let maxHeight: CGFloat = -UIApplication.shared.statusBarFrame.height
    var headerHeightConstraint: CGFloat {
        get {
            return delegate!.returnTableHeight()
        }
        
        set {
            delegate?.setTableHeight(withHeight: newValue)
        }
    }
    var party = Party()
    var previousScrollOffset: CGFloat = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeFontSizeForHub()
    }
    
    func setDelegates() {
        hubTableView.delegate = self
        hubTableView.dataSource = self
    }
    
    // Code taken from https://michiganlabs.com/ios/development/2016/05/31/ios-animating-uitableview-header/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollDiff = scrollView.contentOffset.y - previousScrollOffset
        
        let absoluteTop: CGFloat = 0
        
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteTop && !party.tracksQueue.isEmpty
        var newHeight = headerHeightConstraint
        
        if isScrollingDown {
            newHeight = max(maxHeight, headerHeightConstraint - abs(scrollDiff))
            if newHeight != headerHeightConstraint {
                headerHeightConstraint = newHeight
                changeFontSizeForHub()
                setScrollPosition(for: previousScrollOffset)
            }
            
        } else if isScrollingUp {
            newHeight = min(minHeight, headerHeightConstraint + abs(scrollDiff))
            if newHeight != headerHeightConstraint && hubTableView.contentOffset.y < 2 {
                headerHeightConstraint = newHeight
                changeFontSizeForHub()
                setScrollPosition(for: previousScrollOffset)
            }
        }
        
        
        previousScrollOffset = scrollView.contentOffset.y
    }
    
    func changeFontSizeForHub() {
        UIView.animate(withDuration: 0.3) {
            self.hubLabel.font = self.hubLabel.font.withSize(22 - 6 * (self.headerHeightConstraint / self.minHeight))
        }
    }
    
    func setScrollPosition(for offset: CGFloat) {
        hubTableView.contentOffset = CGPoint(x: hubTableView.contentOffset.x, y: offset)
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
        
        delegate?.layout()
        if headerHeightConstraint > midPoint {
            UIView.animate(withDuration: 0.2, animations: {
                self.headerHeightConstraint = self.minHeight
                self.changeFontSizeForHub()
                self.delegate?.layout()
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.headerHeightConstraint = self.maxHeight
                self.changeFontSizeForHub()
                self.delegate?.layout()
            })
        }
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hubTitles.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Hub Cell")!
        
        cell.textLabel?.text = hubTitles[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if hubTitles[indexPath.row] == "Leave Party" {
            leaveParty()
        } else if !party.tracksQueue.isEmpty && delegate!.getCurrentProgress() != nil {
            MXMLyricsAction.sharedExtension().findLyricsForSong(
                withTitle: party.tracksQueue[0].name,
                artist: party.tracksQueue[0].artist,
                album: party.tracksQueue[0].album,
                artWork: party.tracksQueue[0].highResArtwork,
                currentProgress: delegate!.getCurrentProgress()!,
                trackDuration: party.tracksQueue[0].length!,
                for: self,
                sender: tableView.dequeueReusableCell(withIdentifier: "Hub Cell")!,
                competionHandler: nil)
        }
    }
    
    // MARK: = Navigation
    
    func leaveParty() {
        let _ = navigationController?.popToRootViewController(animated: true)
    }
}
