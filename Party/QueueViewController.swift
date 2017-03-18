//
//  QueueViewController.swift
//  
//
//  Created by Ali Siddiqui on 3/15/17.
//
//

import UIKit

class QueueViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var delegate: PartyViewControllerInfoDelegate?

    @IBOutlet weak var upNextLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var tracksTableView: UITableView!
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
    var previousScrollOffset: CGFloat = 0
    
    var party = Party()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDelegates()
    }
    
    func makeTracksTableTaller() {
        delegate?.layout()
        UIView.animate(withDuration: 0.4) {
            self.headerHeightConstraint = self.maxHeight
            self.changeFontSizeForUpNext()
            self.delegate?.layout()
        }
    }
    
    func makeTracksTableShorter() {
        delegate?.layout()
        UIView.animate(withDuration: 0.4) {
            self.headerHeightConstraint = self.minHeight
            self.changeFontSizeForUpNext()
            self.delegate?.layout()
        }
        tracksTableView.setEditing(false, animated: true)
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
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteTop && party.tracksQueue.count > 0
        
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
        if delegate!.amHost() {
            self.editButton.isHidden = true
            self.addButton.isHidden = false
        }
    }
    
    func goIntoEditingMode() {
        if delegate!.amHost() && party.tracksQueue.count > 1 {
            self.editButton.isHidden = false
            self.addButton.isHidden = true
        }
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
        
        if let unwrappedArtwork = party.tracksQueue[indexPath.row + 1].artwork {
            cell.artworkImageView.image = unwrappedArtwork
        }
        cell.trackName.text = party.tracksQueue[indexPath.row + 1].name
        cell.artistName.text = party.tracksQueue[indexPath.row + 1].artist
        
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
            print("Set editing to on")
            tracksTableView.setEditing(true, animated: true)
            sender.setTitle("Done", for: .normal)
        } else {
            tracksTableView.setEditing(false, animated: true)
            sender.setTitle("Edit", for: .normal)
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if !delegate!.amHost() {
           /* for track in personalQueue {
                if track.id == party.tracksQueue[indexPath.section].id {
                    return true
                }
            }*/
            return false
        } else {
            return true
        }
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemMoved = party.tracksQueue[sourceIndexPath.row + 1]
        party.tracksQueue.remove(at: sourceIndexPath.row + 1)
        party.tracksQueue.insert(itemMoved, at: destinationIndexPath.row + 1)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            removeFromQueue(track: party.tracksQueue[indexPath.row + 1])
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func removeFromQueue(track: Track) {
        for trackInQueue in party.tracksQueue {
            if trackInQueue.id == track.id {
                party.tracksQueue.remove(at: party.tracksQueue.index(of: trackInQueue)!)
                delegate?.removeFromOthersQueue(forTrack: track)
            }
        }
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
        
        
        deleteButton.backgroundColor = UIColor(colorLiteralRed: 1, green: 111/255, blue: 1/255, alpha: 1)
        
        return [deleteButton]
    }
    
}
