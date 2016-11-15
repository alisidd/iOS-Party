//
//  PartyListCell.swift
//  Party
//
//  Created by Matthew on 2016-11-14.
//  Copyright © 2016 Ali Siddiqui.MatthewPaletta. All rights reserved.
//

import UIKit

class PartyListCell: UITableViewCell {

    @IBOutlet weak var partyNameLabel: UILabel!
    @IBOutlet weak var isLockedImage: UIImageView!
    @IBOutlet weak var passwordField: UITextField!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
