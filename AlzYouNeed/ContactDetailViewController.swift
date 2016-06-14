//
//  ContactDetailViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Contacts

class ContactDetailViewController: UIViewController {
    
    var person: Person!
    
    @IBOutlet var contactImage: UIImageView!
    @IBOutlet var fullName: UILabel!
    @IBOutlet var address: UILabel!
    @IBOutlet var email: UILabel!
    
//    var contactItem: CNContact? {
//        didSet {
//            // Update view
//            self.configureView()
//        }
//    }
    
    @IBOutlet var contactCard: ContactView!
    
    func configureView() {
        contactCard.nameLabel.text = "\(person.firstName) \(person.lastName)"
        contactCard.leftButton.setTitle("Call", forState: UIControlState.Normal)
        contactCard.rightButton.setTitle("Message", forState: UIControlState.Normal)
        
        contactCard.leftButton.addTarget(self, action: #selector(ContactDetailViewController.leftButtonPressed(_:)), forControlEvents: [UIControlEvents.TouchUpInside])
        
        // Check if saved image to load
        if let imagePhotoPath = person.photoPath {
            contactCard.setImageWithPath(imagePhotoPath)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func leftButtonPressed(sender: UIButton) {
        print("Left button pressed")
        print("Calling: \(person.phoneNumber)")
//        let telephoneNumber = (person.phoneNumber as CNPhoneNumber).stringValue
        let url: NSURL = NSURL(string: "tel://\(person.phoneNumber)")!
//        let url: NSURL = NSURL(string: "tel://123456789")!

        UIApplication.sharedApplication().openURL(url)
    }
    

    // MARK: - Unused
    //    func configureView() {
    //        // Check that contact is not nil and update interface
    //        if let oldContact = self.contactItem {
    //            let store = CNContactStore()
    //
    //            do {
    //               let keysToFetch = [CNContactFormatter.descriptorForRequiredKeysForStyle(.FullName), CNContactEmailAddressesKey, CNContactPostalAddressesKey, CNContactImageDataKey, CNContactImageDataAvailableKey]
    //
    //                let contact = try store.unifiedContactWithIdentifier(oldContact.identifier, keysToFetch: keysToFetch)
    //
    //                dispatch_async(dispatch_get_main_queue(), {
    //                    // Handle image data
    //                    if contact.imageDataAvailable {
    //                        if let data = contact.imageData {
    //                            self.contactImage.image = UIImage(data: data)
    //                        }
    //                    }
    //                    // Handle full name
    //                    self.fullName.text = CNContactFormatter().stringFromContact(contact)
    //
    //                    // Handle email
    //                    if contact.isKeyAvailable(CNContactEmailAddressesKey) {
    //                        if let emailAddress = contact.emailAddresses.first?.value as? String {
    //                            self.email.text = emailAddress
    //                        }
    //                        else {
    //                            self.email.text = "No Email"
    //                        }
    //                    }
    //
    //                    // Handle Postal Address
    //                    if contact.isKeyAvailable(CNContactPostalAddressesKey) {
    //                        if let postalAddress = contact.postalAddresses.first?.value as? CNPostalAddress {
    //                            self.address.text = CNPostalAddressFormatter().stringFromPostalAddress(postalAddress)
    //                        }
    //                        else {
    //                            self.address.text = "No Address"
    //                        }
    //                    }
    //                    
    //                })
    //            }
    //            catch {
    //                print(error)
    //            }
    //        }
    //    }
    
}
