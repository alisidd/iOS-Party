//
//  PlaylistSubcategoryTableViewCell.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/11/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit
import M13Checkbox

protocol PlaylistSubcategoryTableViewCellDelegate: class {
    func addWholePlaylist(withAddPlaylistButton addPlaylistButton: M13Checkbox, atCell cell: PlaylistSubcategoryTableViewCell)
}

class PlaylistSubcategoryTableViewCell: UITableViewCell {

    weak var delegate: PlaylistSubcategoryTableViewCellDelegate?
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var addPlaylistButton: M13Checkbox!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UIDevice.deviceType == .iPhone4_4s || UIDevice.deviceType == .iPhone5_5s_SE {
            optionLabel.changeToSmallerFont()
        }
    }
    @IBAction func addWholePlaylist(_ sender: M13Checkbox) {
        delegate?.addWholePlaylist(withAddPlaylistButton: sender, atCell: self)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        DispatchQueue.main.async {
            if highlighted {
                self.optionLabel.textColor = AppConstants.orange
            } else {
                self.optionLabel.textColor = .white
            }
        }
    }
    
}
