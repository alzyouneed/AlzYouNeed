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
    func configureCell(_ contact: Contact, row: Int) {
        contactView.nameLabel.text = contact.fullName
        
        // TODO: Change later to add functionality
//        contactView.singleButton("left")
        
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
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async(execute: {
            if let imageUrl = contact.photoUrl {
                if imageUrl.hasPrefix("gs://") {
                    FIRStorage.storage().reference(forURL: imageUrl).data(withMaxSize: INT64_MAX, completion: { (data, error) in
                        if let error = error {
                            // Error
                            print("Error downloading user profile image: \(error.localizedDescription)")
                            return
                        }
                        // Success
                            let image = UIImage(data: data!)
                            DispatchQueue.main.async(execute: {
                                self.contactView.contactImageView.image = image
                            })
                    })
                } else if let url = URL(string: imageUrl), let data = try? Data(contentsOf: url) {
                        let image = UIImage(data: data)
                        DispatchQueue.main.async(execute: {
                            self.contactView.contactImageView.image = image
                        })
                }
            }
        })
    }
  
}
