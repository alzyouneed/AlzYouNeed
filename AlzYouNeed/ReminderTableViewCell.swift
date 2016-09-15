//
//  ReminderTableViewCell.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/10/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

protocol ReminderTableViewCellDelegate {
    func cellButtonTapped(_ cell: ReminderTableViewCell)
}

class ReminderTableViewCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var repeatsLabel: UILabel!
    
    @IBOutlet var completedButton: UIButton!
    
    var delegate: ReminderTableViewCellDelegate?
    
    @IBAction func buttonTapped(_ sender: UIButton) {
        delegate?.cellButtonTapped(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
