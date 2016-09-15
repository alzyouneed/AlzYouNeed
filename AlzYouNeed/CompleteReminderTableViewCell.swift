//
//  CompleteReminderTableViewCell.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class CompleteReminderTableViewCell: UITableViewCell {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
