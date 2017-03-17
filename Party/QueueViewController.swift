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

    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var tracksTableView: UITableView!
    let minHeight: CGFloat = 351
    let maxHeight: CGFloat = 10
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
    
    func setDelegates() {
        tracksTableView.delegate = self
        tracksTableView.dataSource = self
    }
    
    // Code taken from https://michiganlabs.com/ios/development/2016/05/31/ios-animating-uitableview-header/
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let scrollDiff = scrollView.contentOffset.y - previousScrollOffset

        let absoluteTop: CGFloat = 0;
        
        let isScrollingDown = scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop
        let isScrollingUp = scrollDiff < 0 && scrollView.contentOffset.y < absoluteTop
        
        var newHeight = headerHeightConstraint
        
        if isScrollingDown {
            newHeight = max(maxHeight, headerHeightConstraint - abs(scrollDiff))
            if newHeight != headerHeightConstraint {
                headerHeightConstraint = newHeight
                setScrollPosition(for: previousScrollOffset)
            }
            
        } else if isScrollingUp {
            newHeight = min(minHeight, headerHeightConstraint + abs(scrollDiff))
            print(tracksTableView.contentOffset)
            if newHeight != headerHeightConstraint && tracksTableView.contentOffset.y < 2 {
                headerHeightConstraint = newHeight
                setScrollPosition(for: previousScrollOffset)
            }
        }
        
        
        previousScrollOffset = scrollView.contentOffset.y
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
                self.delegate?.layout()
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                self.headerHeightConstraint = self.maxHeight
                self.delegate?.layout()
            })
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
    
    /*

    @IBAction func editCells(_ sender: UIButton) {
        if sender.titleLabel?.text == "Edit" {
            print("Set editing to on")
            setEditing(true, animated: true)
            sender.titleLabel?.text = "Done"
        } else {
            setEditing(false, animated: true)
            sender.titleLabel?.text = "Edit"
        }
        
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if !delegate!.amHost() {
            print("Can't edit :(")
           /* for track in personalQueue {
                if track.id == party.tracksQueue[indexPath.section].id {
                    return true
                }
            }*/
            return false
        } else {
            print("Can edit")
            return true
        }
    }
    
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            removeFromQueue(track: party.tracksQueue[indexPath.section])
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
    }*/
    
}
