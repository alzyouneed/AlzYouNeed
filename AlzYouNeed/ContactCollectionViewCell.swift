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
    
    func configureCell(contact: Contact) {
        contactView.nameLabel.text = contact.fullName
        
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
