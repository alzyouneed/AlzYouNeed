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
        
        // Check user type
        if let userIsAdmin = contact.admin as String? {
            if userIsAdmin == "true" {
                contactView.specialUser("admin")
            } else {
                if let userIsPatient = contact.patient as String? {
                    if userIsPatient == "true" {
                        contactView.specialUser("patient")
                    } else {
                        contactView.specialUser("none")
                    }
                }
            }
        }
        
        // Load images on background thread to avoid choppiness
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), {
            if let imageUrl = contact.photoUrl {
                if imageUrl.hasPrefix("gs://") {
                    FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX, completion: { (data, error) in
                        if let error = error {
                            // Error
                            print("Error downloading user profile image: \(error.localizedDescription)")
                            return
                        }
                        // Success
                            let image = UIImage(data: data!)
                            dispatch_async(dispatch_get_main_queue(), {
                                self.contactView.contactImageView.image = image
                            })
                    })
                } else if let url = NSURL(string: imageUrl), data = NSData(contentsOfURL: url) {
                        let image = UIImage(data: data)
                        dispatch_async(dispatch_get_main_queue(), {
                            self.contactView.contactImageView.image = image
                        })
                }
            }
        })
    }
  
}
