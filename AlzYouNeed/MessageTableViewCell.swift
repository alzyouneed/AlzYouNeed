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

protocol MessageTableViewCellDelegate {
    func cellButtonTapped(cell: MessageTableViewCell)
}

class MessageTableViewCell: UITableViewCell {
    
    @IBOutlet var messageView: MessageView!
    
    var delegate: MessageTableViewCellDelegate?
    
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var chatBubbleView: UIView!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var favoriteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(message: Message, contact: Contact, profileImage: UIImage) {
        self.alpha = 0
        
        chatBubbleView.layer.cornerRadius = 10
        profileImageView.layer.cornerRadius = profileImageView.frame.height/2
        profileImageView.layer.masksToBounds = true
        profileImageView.clipsToBounds = true
        profileImageView.layer.borderWidth = 1
        profileImageView.layer.borderColor = stormCloud.CGColor
        
        
        // Configure favorited
        if message.favorited.count > 0 {
            if let currentUser = FIRAuth.auth()?.currentUser {
                for userId in message.favorited.keys {
                    // Message is favorited by current user
                    if userId == currentUser.uid {
                        if message.favorited[userId] == "true" {
                            favoriteButton.selected = true
                            break
                        } else {
                            favoriteButton.selected = false
                        }
                    }
                }
            }
        }
        
        self.messageLabel.text = message.messageString
        // Format readable date
        let date = NSDate(timeIntervalSince1970: Double(message.dateSent)!)
        let dateFormatter = NSDateFormatter()
        
        let calendar = NSCalendar.currentCalendar()
        if calendar.isDateInToday(date) {
            dateFormatter.dateFormat = "h:mm a"
            self.dateLabel.text = "Today, \(dateFormatter.stringFromDate(date))"
        } else if calendar.isDateInYesterday(date) {
            dateFormatter.dateFormat = "h:mm a"
            self.dateLabel.text = "Yesterday, \(dateFormatter.stringFromDate(date))"
        } else {
            dateFormatter.dateFormat = "M/dd/yy h:mm a"
            self.dateLabel.text = "\(dateFormatter.stringFromDate(date))"
        }
        
        if let currentUser = FIRAuth.auth()?.currentUser {
            if message.senderId == currentUser.uid {
                self.nameLabel.text = "Me"
                // Use current user's profile image
                self.profileImageView.image = AYNModel.sharedInstance.currentUserProfileImage
                self.userType("sender")
            } else {
                // Get only first name
                let fullName = contact.fullName
                if let firstName = fullName.componentsSeparatedByString(" ")[0] as String? {
                    self.nameLabel.text = firstName
                } else {
                    self.nameLabel.text = fullName
                }
                // Use recipient's profile image
                self.profileImageView.image = profileImage
                self.userType("receiver")
            }
        }
        
        UIView.animateWithDuration(0.2, animations: {
            self.alpha = 1
        })
    }
    
    private func userType(type: String) {
        switch type {
        case "sender":
            chatBubbleView.backgroundColor = caribbeanGreen
            messageLabel.textColor = UIColor.whiteColor()
        case "receiver":
            chatBubbleView.backgroundColor = columbiaBlue
            messageLabel.textColor = UIColor.blackColor()
        default:
            break
        }
    }
    
    @IBAction func buttonTapped(sender: UIButton) {
        delegate?.cellButtonTapped(self)
    }

}
