//
//  HintTableViewCell.swift
//  WeJ
//
//  Created by Ali Siddiqui on 8/30/17.
//  Copyright © 2017 Mohammad Ali Siddiqui. All rights reserved.
//

import UIKit

class HintTableViewCell: UITableViewCell {

    var hintLabel: UILabel!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        hintLabel = UILabel(frame: CGRect(x: 33, y: 0, width: bounds.width, height: frame.size.height))
        hintLabel.center.y = frame.size.height/2 + 4
        hintLabel.font = UIFont(name: "AvenirNext-Regular", size: 15)
        
        addSubview(hintLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            hintLabel?.textColor = AppConstants.orange
        } else {
            hintLabel?.textColor = .white
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        backgroundColor = .clear
    }

}
