//
//  ContactsCollectionViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/14/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Contacts
import ContactsUI

private let reuseIdentifier = "ContactCell"

class ContactsCollectionViewController: UICollectionViewController, CNContactPickerDelegate {
    
    var userContacts: [Person] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactsTableViewController.insertNewObject(_:)), name: "addNewContact", object: nil)
        
        loadContacts()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - Logic
    
    func loadContacts() {
        userContacts.removeAll()
        userContacts = UserDefaultsManager.getAllContacts()!
        self.collectionView!.reloadData()
        
        print("Loaded \(userContacts.count) contacts from UserDefaults")
    }

    @IBAction func addExistingContact(sender: UIBarButtonItem) {
        addContact()
    }
    
    func addContact() {
        let contactPicker = CNContactPickerViewController()
        
        // Only search contacts with phoneNumbers
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0", argumentArray: nil)
        contactPicker.delegate = self
        self.presentViewController(contactPicker, animated: true, completion: nil)
    }
    
    func insertNewObject(sender: NSNotification) {
        if let contact = sender.userInfo?["contactToAdd"] as? CNContact {
            
            // Check that contact does not already exist
            if !UserDefaultsManager.contactExists(contact.identifier) {
                var contactImage = UIImage()
                // Check for contact image
                if contact.imageDataAvailable {
                    // Use smaller picture to save memory
                    if let data = contact.thumbnailImageData {
//                    if let data = contact.imageData {
                        contactImage = UIImage(data: data)!
                    }
                }
                
                // Create new person using contact
                let person = Person(identifier: contact.identifier, firstName: contact.givenName, lastName: contact.familyName, photo: contactImage, phoneNumber: (contact.phoneNumbers[0].value as! CNPhoneNumber).valueForKey("digits") as? String)
                
                // Add contact to local array
                userContacts.append(person)
                // Save to defaults
                UserDefaultsManager.saveContact(person)
                
                let indexPath = NSIndexPath(forRow: userContacts.count-1, inSection: 0)
//                self.collectionView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                self.collectionView?.insertItemsAtIndexPaths([indexPath])
            }
            else {
                print("Contact already exists")
            }
        }
    }
    
    // MARK: - CNContactPickerDelegate
    
    func contactPicker(picker: CNContactPickerViewController, didSelectContact contact: CNContact) {
        NSNotificationCenter.defaultCenter().postNotificationName("addNewContact", object: nil, userInfo: ["contactToAdd": contact])
    }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return userContacts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ContactCollectionViewCell
    
        let person = userContacts[indexPath.row]
        
        cell.contactView.nameLabel.text = "\(person.firstName) \(person.lastName)"
        cell.contactView.leftButton.setTitle("Call", forState: UIControlState.Normal)
        cell.contactView.rightButton.setTitle("Message", forState: UIControlState.Normal)
        
        // Matches cell buttton to phone number (for calling)
        cell.contactView.leftButton.addTarget(self, action: #selector(ContactDetailViewController.leftButtonPressed(_:)), forControlEvents: [UIControlEvents.TouchUpInside])
        cell.contactView.leftButton.tag = indexPath.row
        
//        cell.contactView.layer.cornerRadius = 10
        
        // Check for saved image to load
        if cell.contactView.contactImageView.image == nil {
            if let imagePhotoPath = person.photoPath {
                cell.contactView.setImageWithPath(imagePhotoPath)
            }
        }
    
        return cell
    }
    
    func leftButtonPressed(sender: UIButton) {
        print("Left button pressed")
        print("Button row: \(sender.tag)")
        
        let phoneNumber = userContacts[sender.tag].phoneNumber
        
        print("Calling: \(phoneNumber)")
        let url: NSURL = NSURL(string: "tel://\(phoneNumber)")!
        
        UIApplication.sharedApplication().openURL(url)
    }
    

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
