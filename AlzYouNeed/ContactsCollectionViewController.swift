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

class ContactsCollectionViewController: UICollectionViewController {
    
    var contacts: [Contact] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create observer for CNContactPicker selection
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactsCollectionViewController.insertNewObject(_:)), name: "addNewContact", object: nil)
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let currentUser = user {
                // User is signed in.
                print("\(currentUser) is logged in")
                
                /*
                // Check if current user has completed signup
                FirebaseManager.getUserSignUpStatus({ (status, error) in
                    if error == nil {
                        if let status = status {
                            switch status {
                            case "updateUser":
                                self.presentUpdateUserVC()
                            case "familySetup":
                                self.presentFamilyVC()
                            default:
                                break
                                
                            }
                        }
                    }
                })
                */
                
            }
            else {
                // No user is signed in.
                print("No user is signed in -- moving to onboarding flow")
                self.presentOnboardingVC()
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        loadContacts()
    }
    
    func presentOnboardingVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("onboardingNav") as! UINavigationController
        self.presentViewController(onboardingVC, animated: true, completion: nil)
    }
    
    func presentFamilyVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: NewExistingFamilyViewController = storyboard.instantiateViewControllerWithIdentifier("familyVC") as! NewExistingFamilyViewController
        let navController = UINavigationController(rootViewController: onboardingVC)
        self.presentViewController(navController, animated: true, completion: nil)

    }
    
    func presentUpdateUserVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let updateUserVC: UpdateUserViewController = storyboard.instantiateViewControllerWithIdentifier("updateUserVC") as! UpdateUserViewController
        let navController = UINavigationController(rootViewController: updateUserVC)
        self.presentViewController(navController, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Logic
    
    func loadContacts() {
        contacts.removeAll()
        self.collectionView?.reloadData()
        FirebaseManager.getFamilyMembers { (members, error) in
            if error == nil {
                if let members = members {
                    print("Loaded \(members.count) contacts from Firebase")
                    self.contacts = members
                    
                    dispatch_async(dispatch_get_main_queue(), { 
                        self.collectionView?.reloadData()
                        self.checkCollectionViewEmpty()
                    })
                }
            }
        }
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
        
        cell.layer.masksToBounds = true
        cell.layer.cornerRadius = 10
    
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
    
    // Add label if table data array empty
    func checkCollectionViewEmpty() {
        if contacts.isEmpty {
            let emptyLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            emptyLabel.text = "Where is everyone?"
            emptyLabel.font = UIFont(name: "OpenSans-Semibold", size: 20)
            emptyLabel.textColor = lightPurple
            emptyLabel.hidden = false
            emptyLabel.alpha = 1
            emptyLabel.textAlignment = NSTextAlignment.Center
            
            self.collectionView!.backgroundView = emptyLabel
//            self.collectionView!.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            self.collectionView!.backgroundView = nil
//            self.collectionView!.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
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
