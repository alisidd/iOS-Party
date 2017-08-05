//
//  LyricsViewController.swift
//  WeJ
//
//  Created by Mohammad Ali Siddiqui on 3/15/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class HubViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    weak var delegate: PartyViewControllerInfoDelegate?
    
    @IBOutlet weak var hubTitle: UILabel?
    private let hubOptions = ["Lyrics", "Leave Party"]
    private let hubIcons = [#imageLiteral(resourceName: "lyricsIcon"), #imageLiteral(resourceName: "leavePartyIcon")]
    @IBOutlet weak var hubTableView: UITableView!
    @IBOutlet weak var hubLabel: UILabel!
    
    private let minHeight: CGFloat = 351
    private let maxHeight: CGFloat = -UIApplication.shared.statusBarFrame.height
    private var headerHeightConstraint: CGFloat {
        get {
            return delegate!.returnTableHeight()
        }
        
        set {
            delegate?.setTable(withHeight: newValue)
        }
    }
    private var previousScrollOffset: CGFloat = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        adjustViews()
        setDelegates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeFontSizeForHub()
    }
    
    func adjustViews() {
        updateHubTitle()
    }
    
    private func setDelegates() {
        hubTableView.delegate = self
        hubTableView.dataSource = self
    }
    
    // Code taken from https://michiganlabs.com/ios/development/2016/05/31/ios-animating-uitableview-header/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollDiff = scrollView.contentOffset.y - previousScrollOffset
        
        let absoluteTop: CGFloat = 0
        
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteTop && !Party.tracksQueue.isEmpty
        var newHeight = headerHeightConstraint
        
        if isScrollingDown {
            newHeight = max(maxHeight, headerHeightConstraint - abs(scrollDiff))
            if newHeight != headerHeightConstraint {
                headerHeightConstraint = newHeight
                changeFontSizeForHub()
                setScrollPosition(forOffset: previousScrollOffset)
            }
            
        } else if isScrollingUp {
            newHeight = min(minHeight, headerHeightConstraint + abs(scrollDiff))
            if newHeight != headerHeightConstraint && hubTableView.contentOffset.y < 2 {
                headerHeightConstraint = newHeight
                changeFontSizeForHub()
                setScrollPosition(forOffset: previousScrollOffset)
            }
        }
        
        
        previousScrollOffset = scrollView.contentOffset.y
    }
    
    private func changeFontSizeForHub() {
        UIView.animate(withDuration: 0.3) {
            self.hubLabel.font = self.hubLabel.font.withSize(22 - 4 * (self.headerHeightConstraint / self.minHeight))
        }
    }
    
    private func setScrollPosition(forOffset offset: CGFloat) {
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
    
    private func scrollViewDidStopScrolling() {
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
    
    func updateHubTitle() {
        guard Party.name != nil else { return }
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.4, animations: { self.hubTitle?.alpha = 0 }, completion: { _ in
                self.hubTitle?.text = Party.name ?? "Hub"
                UIView.animate(withDuration: 0.4) { self.hubTitle?.alpha = 1 }
                
            })
        }
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hubOptions.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Hub Cell") as! HubTableViewCell
        
        cell.hubLabel.text = hubOptions[indexPath.row]
        cell.iconView?.image = hubIcons[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if hubOptions[indexPath.row] == "Leave Party" {
            leaveParty()
        } else if !Party.tracksQueue.isEmpty && MusicPlayer.currentPosition != nil {
            MXMLyricsAction.sharedExtension().findLyricsForSong(
                withTitle: Party.tracksQueue[0].name,
                artist: Party.tracksQueue[0].artist,
                album: "",
                artWork: Party.tracksQueue[0].highResArtwork,
                currentProgress: MusicPlayer.currentPosition!,
                trackDuration: Party.tracksQueue[0].length!,
                for: self,
                sender: tableView.dequeueReusableCell(withIdentifier: "Hub Cell")!,
                competionHandler: nil)
        } else {
            postAlertForNoTracks()
        }
    }
    
    private func postAlertForNoTracks() {
        let alert = UIAlertController(title: "No Tracks Playing", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    // MARK: = Navigation
    
    private func leaveParty() {
        let _ = navigationController?.popToRootViewController(animated: true)
    }
}
