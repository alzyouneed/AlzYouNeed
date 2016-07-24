//
//  ContactsViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/22/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class ContactsViewController: UIViewController, UICollectionViewDelegate {

    // MARK: - UI Elements
    @IBOutlet var contactsCollectionView: UICollectionView!
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureRefreshControl()
        loadContacts(false)
        contactsCollectionView.delegate = self
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
        self.contactsCollectionView.reloadData()
        FirebaseManager.getFamilyMembers { (members, error) in
            if error == nil {
                if let members = members {
                    print("Loaded \(members.count) contacts from Firebase")
                    AYNModel.sharedInstance.contactsArr = members
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        UIView.animateWithDuration(0.5, animations: {
                            self.contactsCollectionView.reloadData()
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
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AYNModel.sharedInstance.contactsArr.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ContactCell", forIndexPath: indexPath) as! ContactCollectionViewCell
        
        let contact = AYNModel.sharedInstance.contactsArr[indexPath.row]

        // Configure cell
        cell.configureCell(contact)
        
        cell.contactView.leftButton.setTitle("Call", forState: UIControlState.Normal)
        cell.contactView.rightButton.setTitle("Message", forState: UIControlState.Normal)
        
        if let userIsAdmin = contact.admin as String? {
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
            emptyLabel.textColor = slateBlue
            emptyLabel.hidden = false
            emptyLabel.alpha = 1
            emptyLabel.textAlignment = NSTextAlignment.Center
            
            self.contactsCollectionView.backgroundView = emptyLabel
            //            self.collectionView!.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            self.contactsCollectionView.backgroundView = nil
            //            self.collectionView!.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        }
    }
    
    // MARK: - Refresh control
    func configureRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: slateBlue, NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 16)!])
        refreshControl.tintColor = slateBlue
        refreshControl.addTarget(self, action: #selector(ContactsCollectionViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        contactsCollectionView.addSubview(refreshControl)
    }
    
    
    // MARK: - Navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "contactDetail" {
            let detailNavController: UINavigationController = segue.destinationViewController as! UINavigationController
            if self.contactsCollectionView.indexPathsForSelectedItems()?.count > 0 {
                if let indexPath = self.contactsCollectionView.indexPathsForSelectedItems()![0] as NSIndexPath? {
                    let contact = AYNModel.sharedInstance.contactsArr[indexPath.row]
                    if let detailVC: ContactDetailViewController = detailNavController.childViewControllers[0] as? ContactDetailViewController {
                        detailVC.contact = contact
                    }
                }
            }
        }
    }

}
