//
//  MessageTableViewCell.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/29/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet var messageView: MessageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configureCell(message: Message, contact: Contact, profileImage: UIImage) {
        messageView.alpha = 0
        
        dispatch_async(dispatch_get_main_queue()) {
            self.messageView.messageLabel.text = message.messageString
            
            // Format readable date
            let date = NSDate(timeIntervalSince1970: Double(message.dateSent)!)
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "M/dd/yy h:mm a"
            self.messageView.dateLabel.text = "\(dateFormatter.stringFromDate(date))"
            
            if let currentUser = FIRAuth.auth()?.currentUser {
                if message.senderId == currentUser.uid {
                    self.messageView.nameLabel.text = "Me"
                    // Use current user's profile image
                    self.messageView.profileImageView.image = AYNModel.sharedInstance.currentUserProfileImage
                    self.messageView.userType("sender")
                } else {
                    // Get only first name
                    let fullName = contact.fullName
                    if let firstName = fullName.componentsSeparatedByString(" ")[0] as String? {
                        self.messageView.nameLabel.text = firstName
                    } else {
                        self.messageView.nameLabel.text = fullName
                    }
                    // Use recipient's profile image
                    self.messageView.profileImageView.image = profileImage
                    self.messageView.userType("receiver")
                }
            }
            
            UIView.animateWithDuration(0.2, animations: {
                self.messageView.alpha = 1
            })
        }
    }

}
