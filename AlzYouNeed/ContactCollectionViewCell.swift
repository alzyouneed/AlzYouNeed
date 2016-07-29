//
//  ContactCollectionViewCell.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/14/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class ContactCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var contactView: ContactView!
    
//    func configureCell(contact: Contact) {
    func configureCell(contact: Contact, row: Int) {
        contactView.nameLabel.text = contact.fullName
        
        // TODO: Change later to add functionality
        contactView.singleButton("left")
        
        // Saves row in tag for contact-specific actions
        contactView.leftButton.tag = row
        contactView.rightButton.tag = row
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10
        
        if let userIsAdmin = contact.admin as String? {
            if userIsAdmin == "true" {
                contactView.isAdmin(true)
            }
            else {
                contactView.isAdmin(false)
            }
        }
        
        if let imageUrl = contact.photoUrl {
            if imageUrl.hasPrefix("gs://") {
                FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX, completion: { (data, error) in
                    if let error = error {
                        // Error
                        print("Error downloading user profile image: \(error.localizedDescription)")
                        return
                    }
                    // Success
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.contactView.contactImageView.image = UIImage(data: data!)
                    })
                })
            } else if let url = NSURL(string: imageUrl), data = NSData(contentsOfURL: url) {
                dispatch_async(dispatch_get_main_queue(), {
                    self.contactView.contactImageView.image = UIImage(data: data)
                })
            }
        }
    }
  
}
