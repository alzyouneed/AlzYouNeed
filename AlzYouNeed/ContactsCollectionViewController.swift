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
import Firebase

private let reuseIdentifier = "ContactCell"

class ContactsCollectionViewController: UICollectionViewController, CNContactPickerDelegate {
    
    var userContacts: [Person] = []
    
    var contacts: [Contact] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create observer for CNContactPicker selection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactsCollectionViewController.insertNewObject(_:)), name: "addNewContact", object: nil)
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let currentUser = user {
                // User is signed in.
                print("\(currentUser) is logged in")
                
                // Check if current user has completed signup
                FirebaseManager.getUserSignUpStatus({ (status, error) in
                    if error == nil {
                        if let signupStatus = status {
                            if signupStatus == "false" {
                                // Signup not complete -- Switch to family VC
                                print("User has not completed signup -- moving to family VC")
                                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                                let onboardingVC: NewExistingFamilyViewController = storyboard.instantiateViewControllerWithIdentifier("familyVC") as! NewExistingFamilyViewController
                                let navController = UINavigationController(rootViewController: onboardingVC)
                                self.presentViewController(navController, animated: true, completion: nil)
                            }
                        }
                    }
                })
                
            } else {
                // No user is signed in.
                print("No user is signed in -- moving to onboarding flow")
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("onboardingNav") as! UINavigationController
                self.presentViewController(onboardingVC, animated: true, completion: nil)
            }
        }
        
        contacts.removeAll()
    }
    
    override func viewDidAppear(animated: Bool) {
        
//        getCurrentFamily { (familyId) in
//            print("Current family: \(familyId)")
//            FirebaseManager.getFamilyMembers(familyId, completionHandler: { (contacts, error) in
//                if error == nil {
//                    if let contactsArr = contacts {
//                        for person in contactsArr {
//                            print(person)
//                        }
//                        
//                        self.contacts.removeAll()
//                        self.contacts = contactsArr
//                        self.collectionView?.reloadData()
//                    }
//                }
//            })
//        }
        
//        FirebaseManager.getCurrentUser { (userDict, error) in
//            if error == nil {
//                print("Current user: \(userDict)")
//            }
//        }
        
        FirebaseManager.getFamilyMembers { (members, error) in
            if error == nil {
                if let members = members {
                    print("Members: \(members)")
                    self.contacts.removeAll()
                    self.contacts = members
                    self.collectionView?.reloadData()
                }
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
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
            
            print("Adding contact: \(contact.givenName) \(contact.familyName) \n")
            
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
    
    // MARK: - UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return userContacts.count
        return contacts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ContactCollectionViewCell
    
//        let person = userContacts[indexPath.row]
        
        let person = contacts[indexPath.row]
        
        // Configure cell
        cell.contactView.nameLabel.text = "\(person.fullName)"
        cell.contactView.leftButton.setTitle("Call", forState: UIControlState.Normal)
        cell.contactView.rightButton.setTitle("Message", forState: UIControlState.Normal)
        
        if let userImage = UIImage(named: person.avatarId) {
            cell.contactView.contactImageView.image = userImage
        }
        
        // Add targets for both buttons
        cell.contactView.leftButton.addTarget(self, action: #selector(ContactsCollectionViewController.leftButtonPressed(_:)), forControlEvents: [UIControlEvents.TouchUpInside])
        cell.contactView.rightButton.addTarget(self, action: #selector(ContactsCollectionViewController.rightButtonPressed(_:)), forControlEvents: [UIControlEvents.TouchUpInside])
        
        // Saves row in tag for contact-specific actions
        cell.contactView.leftButton.tag = indexPath.row
        cell.contactView.rightButton.tag = indexPath.row
    
        return cell
    }
    
    // MARK: - Contact Card Actions
    
    func leftButtonPressed(sender: UIButton) {
        
//        let phoneNumber = userContacts[sender.tag].phoneNumber
        
        let phoneNumber = contacts[sender.tag].phoneNumber
        print("Left button pressed -- row: \(sender.tag) -- Calling: \(phoneNumber) \n")

        let url: NSURL = NSURL(string: "tel://\(phoneNumber)")!
        
        UIApplication.sharedApplication().openURL(url)
    }
    
    func rightButtonPressed(sender: UIButton) {
        print("Right button pressed -- row: \(sender.tag)")
    }
    
    func getCurrentFamily(completionHandler:(String)->()){
        if let currentUser = FIRAuth.auth()?.currentUser {
            let userId = currentUser.uid
            let databaseRef = FIRDatabase.database().reference()
            
            databaseRef.child("users").child(userId).observeSingleEventOfType(.Value, withBlock: { (snapshot) in
                if let familyId = snapshot.value!["familyId"] as? String {
                    completionHandler(familyId)
                }
            }) { (error) in
                print(error.localizedDescription)
            }
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using [segue destinationViewController].
     // Pass the selected object to the new view controller.
     }
     */

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
