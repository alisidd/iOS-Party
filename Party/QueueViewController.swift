//
//  QueueViewController.swift
//  
//
//  Created by Ali Siddiqui on 3/15/17.
//
//

import UIKit

class QueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: PartyViewControllerInfoDelegate?

    @IBOutlet weak var upNextLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var tracksTableView: UITableView!

    let minHeight: CGFloat = 0.53 * UIScreen.main.bounds.height
    let maxHeight: CGFloat = -UIApplication.shared.statusBarFrame.height
    var headerHeightConstraint: CGFloat {
        get {
            return delegate?.returnTableHeight() ?? maxHeight
        }
        
        set {
            delegate?.setTableHeight(withHeight: newValue)
        }
    }
    var previousScrollOffset: CGFloat = 0
    
    var party = Party()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        changeFontSizeForUpNext()
    }
    
    func makeTracksTableTaller() {
        DispatchQueue.main.async {
            self.delegate?.layout()
            UIView.animate(withDuration: 0.4) {
                self.headerHeightConstraint = self.maxHeight
                self.changeFontSizeForUpNext()
                self.delegate?.layout()
            }
            if self.party.tracksQueue.isEmpty {
                self.comeOutOfEditingMode()
            }
        }
    }
    
    func makeTracksTableShorter() {
        DispatchQueue.main.async {
            self.delegate?.layout()
            UIView.animate(withDuration: 0.4) {
                self.headerHeightConstraint = self.minHeight
                self.changeFontSizeForUpNext()
                self.delegate?.layout()
            }
            self.comeOutOfEditingMode()
        }
    }
    
    func setDelegates() {
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
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
                changeFontSizeForUpNext()
                setScrollPosition(for: previousScrollOffset)
            }
            
        } else if isScrollingUp {
            newHeight = min(minHeight, headerHeightConstraint + abs(scrollDiff))
            if newHeight != headerHeightConstraint && tracksTableView.contentOffset.y < 2 {
                headerHeightConstraint = newHeight
                changeFontSizeForUpNext()
                setScrollPosition(for: previousScrollOffset)
            }
        }
        
        
        previousScrollOffset = scrollView.contentOffset.y
    }
    
    func changeFontSizeForUpNext() {
        UIView.animate(withDuration: 0.3) {
            self.upNextLabel.font = self.upNextLabel.font.withSize(22 - 6 * (self.headerHeightConstraint / self.minHeight))
        }
    }
    
    func setScrollPosition(for offset: CGFloat) {
        tracksTableView.contentOffset = CGPoint(x: tracksTableView.contentOffset.x, y: offset)
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
                self.changeFontSizeForUpNext()
                self.delegate?.layout()
                self.comeOutOfEditingMode()
                
                self.tracksTableView.setEditing(false, animated: true)
                self.comeOutOfEditingMode()
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.headerHeightConstraint = self.maxHeight
                self.changeFontSizeForUpNext()
                self.delegate?.layout()
                self.goIntoEditingMode()
            })
        }
    }
    
    func comeOutOfEditingMode() {
        editButton.isHidden = true
        addButton.isHidden = false
        editButton.setTitle("Edit", for: .normal)
    }
    
    func goIntoEditingMode() {
        if (delegate!.amHost() && party.tracksQueue.count > 1) || tracksQueueHasEditableTracks() {
            editButton.isHidden = false
            addButton.isHidden = true
        }
    }
    
    func tracksQueueHasEditableTracks() -> Bool {
        for track in party.tracksQueue {
            if delegate!.personalQueue(hasTrack: track) && track != party.tracksQueue[0] {
                return true
            }
        }
        return false
    }
    
    // MARK: - Table
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return party.tracksQueue.count - 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        cell.backgroundColor = .clear
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Track In Queue") as! TrackTableViewCell
        
        if party.tracksQueue.count > indexPath.row {
            if let unwrappedArtwork = party.tracksQueue[indexPath.row + 1].lowResArtwork {
                cell.artworkImageView.image = unwrappedArtwork
            } else {
                cell.artworkImageView.image = nil
            }
            cell.trackName.text = party.tracksQueue[indexPath.row + 1].name
            cell.artistName.text = party.tracksQueue[indexPath.row + 1].artist
        }
        
        return cell
    }
    
    func updateTable() {
        DispatchQueue.main.async {
            self.tracksTableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Add Tracks" {
            if let vc = segue.destination as? AddSongViewController {
                vc.party = party
            }
        }
    }

    @IBAction func editCells(_ sender: UIButton) {
        if sender.titleLabel?.text == "Edit" {
            tracksTableView.setEditing(true, animated: true)
            sender.setTitle("Done", for: .normal)
        } else {
            tracksTableView.setEditing(false, animated: true)
            sender.setTitle("Edit", for: .normal)
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if !delegate!.amHost() && !delegate!.personalQueue(hasTrack: party.tracksQueue[indexPath.row + 1]){
            return false
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if delegate!.amHost() {
            return true
        }
        return false
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemMoved = party.tracksQueue[sourceIndexPath.row + 1]
        party.tracksQueue.remove(at: sourceIndexPath.row + 1)
        party.tracksQueue.insert(itemMoved, at: destinationIndexPath.row + 1)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            removeTrack(atIndex: indexPath.row + 1)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func removeTrack(atIndex index: Int) {
        let track = party.tracksQueue[index]
        party.tracksQueue.remove(at: index)
        delegate?.removeFromOthersQueue(forTrack: track)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
            tableView.dataSource?.tableView?(
                tableView,
                commit: .delete,
                forRowAt: indexPath
            )
            return
        })
        
        return [deleteButton]
    }
    
}
