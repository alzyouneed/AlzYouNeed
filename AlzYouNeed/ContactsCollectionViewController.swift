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
    
    // MARK: - UI Elements
    var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRefreshControl()
        loadContacts(false)
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        // If new user signed in -- force reload contacts
        if AYNModel.sharedInstance.contactsArrWasReset {
            AYNModel.sharedInstance.contactsArrWasReset = false
            print("Model was reset -- loading contacts")
            loadContacts(false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Logic
    func loadContacts(refreshing: Bool) {
        AYNModel.sharedInstance.contactsArr.removeAll()
        self.collectionView?.reloadData()
        FirebaseManager.getFamilyMembers { (members, error) in
            if error == nil {
                if let members = members {
                    print("Loaded \(members.count) contacts from Firebase")
                    AYNModel.sharedInstance.contactsArr = members
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        UIView.animateWithDuration(0.5, animations: { 
                            self.collectionView?.reloadData()
                            self.checkCollectionViewEmpty()
                            
                            if refreshing {
                                self.refreshControl.endRefreshing()
                            }
                        })
                    })
                }
            }
        }
    }
    
    func refresh(control: UIRefreshControl) {
        print("Refreshing")
        loadContacts(true)
    }
    
    // MARK: - UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AYNModel.sharedInstance.contactsArr.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ContactCollectionViewCell

        let person = AYNModel.sharedInstance.contactsArr[indexPath.row]
        
        // Configure cell
        cell.contactView.nameLabel.text = "\(person.fullName)"
        cell.contactView.leftButton.setTitle("Call", forState: UIControlState.Normal)
        cell.contactView.rightButton.setTitle("Message", forState: UIControlState.Normal)
        
        if let userImage = UIImage(named: person.avatarId) {
            cell.contactView.contactImageView.image = userImage
        }
        
        if let userIsAdmin = person.admin as String? {
            if userIsAdmin == "true" {
                cell.contactView.isAdmin(true)
            }
            else {
                cell.contactView.isAdmin(false)
            }
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
        let phoneNumber = AYNModel.sharedInstance.contactsArr[sender.tag].phoneNumber
        print("Left button pressed -- row: \(sender.tag) -- Calling: \(phoneNumber) \n")

        let url: NSURL = NSURL(string: "tel://\(phoneNumber)")!
        
        UIApplication.sharedApplication().openURL(url)
    }
    
    func rightButtonPressed(sender: UIButton) {
        print("Right button pressed -- row: \(sender.tag)")
    }
    
    // Add label if table data array empty
    func checkCollectionViewEmpty() {
        if AYNModel.sharedInstance.contactsArr.isEmpty {
            let emptyLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            emptyLabel.text = "Where is everyone?"
            emptyLabel.font = UIFont(name: "OpenSans-Semibold", size: 20)
            emptyLabel.textColor = stormCloud
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
    
    // MARK: - Refresh control
    func configureRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor(), NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 16)!])
        refreshControl.tintColor = UIColor.whiteColor()
        refreshControl.addTarget(self, action: #selector(ContactsCollectionViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        collectionView?.addSubview(refreshControl)
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
