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
    
    func configureCell(message: Message) {
        
        messageView.alpha = 0
        
        FirebaseManager.getUserById(message.senderId) { (userDict, error) in
            if error == nil {
                if let userDict = userDict {
                    
                    dispatch_async(dispatch_get_main_queue(), {
//                        self.messageView.nameLabel.text = userDict.objectForKey("name") as! String!
                        
                        let photoUrl = userDict.objectForKey("photoUrl") as! String!
                        self.messageView.profileImageView.image = self.getProfileImage(photoUrl)
                        
                        self.messageView.messageLabel.text = message.messageString
                        
                        if let currentUser = FIRAuth.auth()?.currentUser {
                            if message.senderId == currentUser.uid {
                                self.messageView.nameLabel.text = "Me"
                                self.messageView.userType("sender")
                            } else {
                                self.messageView.nameLabel.text = userDict.objectForKey("name") as! String!
                               self.messageView.userType("receiver")
                            }
                        }
                        
                        UIView.animateWithDuration(0.2, animations: { 
                            self.messageView.alpha = 1
                        })
                    })
                }
            }
        }
    }
    
    private func getProfileImage(photoUrl: String) -> UIImage? {
        var profileImage = UIImage()
        if let photoUrl = photoUrl as String? {
            if photoUrl.hasPrefix("gs://") {
                FIRStorage.storage().referenceForURL(photoUrl).dataWithMaxSize(INT64_MAX, completion: { (data, error) in
                    if let error = error {
                        // Error
                        print("Error downloading user profile image: \(error.localizedDescription)")
                        return
                    }
                    // Success
                    profileImage = UIImage(data: data!)!
                })
            } else if let url = NSURL(string: photoUrl), data = NSData(contentsOfURL: url) {
                    profileImage = UIImage(data: data)!
            }
        }
        return profileImage
    }

}
