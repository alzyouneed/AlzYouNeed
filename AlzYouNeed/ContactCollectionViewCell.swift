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
import FontAwesome_swift

class ContactCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var contactView: ContactView!
    
    func configureCell(_ contact: Contact, row: Int) {
        contactView.nameLabel.text = contact.name
        
        // Saves row in tag for contact-specific actions
        contactView.leftButton.tag = row
        contactView.rightButton.tag = row
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10
        
        // Check user type
//        if let userIsAdmin = contact.admin as String? {
//            if userIsAdmin == "true" {
//                contactView.specialUser("admin")
//            } else {
//                if let userIsPatient = contact.patient as String? {
//                    if userIsPatient == "true" {
//                        contactView.specialUser("patient")
//                    } else {
//                        contactView.specialUser("none")
//                    }
//                }
//            }
//        }
        
        if contact.phoneNumber == nil {
            contactView.leftButton.isEnabled = false
            contactView.leftButton.alpha = 0.7
        }
        
        // Load images on background thread to avoid choppiness
        DispatchQueue.global().async {
            var foundCache = false
            for arrContact in AYNModel.sharedInstance.contactsArr {
                if arrContact.userId == contact.userId {
                    // Found user -- check for image
                    if let userPhoto = arrContact.photo {
                        print("Found cached user photo")
                        foundCache = true
                        DispatchQueue.main.async(execute: {
                            self.contactView.contactImageView.image = userPhoto
                        })
                        return
                    }
                }
            }
            if !foundCache {
//                print("No cached user photo -- downloading")
                
                // Disable user interaction with cell for now to prevent unwrapping errors
                self.isUserInteractionEnabled = false
                
                // Background thread
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
                                // Save image for later reuse
                                AYNModel.sharedInstance.contactsArr[row].photo = image
                                
                                // Enable user interaction again
                                self.isUserInteractionEnabled = true
                            })
                        })
                    } else if let url = URL(string: imageUrl), let data = try? Data(contentsOf: url) {
                        let image = UIImage(data: data)
                        DispatchQueue.main.async(execute: {
                            self.contactView.contactImageView.image = image
                            // save image for later reuse
                            AYNModel.sharedInstance.contactsArr[row].photo = image
                            
                            // Enable user interaction again
                            self.isUserInteractionEnabled = true
                        })
                    }
                }  else {
                    // No image found
                    self.isUserInteractionEnabled = true
                    DispatchQueue.main.async {
                        self.contactView.contactImageView.image = UIImage.fontAwesomeIcon(name: .user, textColor: UIColor(hex: "7189FF"), size: CGSize(width: 100, height: 100))
                    }
                }
            }
        }
    }
    
}
