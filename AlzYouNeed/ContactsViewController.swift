//
//  ContactsViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/22/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
//import PKHUD

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


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
    
    override func viewWillAppear(_ animated: Bool) {
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
    func loadContacts(_ refreshing: Bool) {
        AYNModel.sharedInstance.contactsArr.removeAll()
//        self.contactsCollectionView.reloadData()
        
        if !refreshing {
            // Show progress view
            //HUD.show(.Progress)
        }
        
        FirebaseManager.getFamilyMembers { (members, error) in
            if error == nil {
                if let members = members {
                    // HUD.hide()
                    print("Loaded \(members.count) contacts from Firebase")
                    AYNModel.sharedInstance.contactsArr = members
                    
                    DispatchQueue.main.async(execute: {
                        self.contactsCollectionView.reloadData()
                        self.checkCollectionViewEmpty()
                        
                        if refreshing {
                            self.refreshControl.endRefreshing()
                        }
                    })
                }
            } else {
                // Error
                // HUD.hide()
            }
        }
    }
    
    func refresh(_ control: UIRefreshControl) {
        print("Refreshing")
        loadContacts(true)
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(_ collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return AYNModel.sharedInstance.contactsArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAtIndexPath indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactCell", for: indexPath) as! ContactCollectionViewCell
        
        let contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]

        // Configure cell
//        dispatch_async(dispatch_get_main_queue()) { 
//            cell.configureCell(contact, row: indexPath.row)
//        }
        cell.configureCell(contact, row: (indexPath as NSIndexPath).row)
        
        // Add targets for both buttons
        cell.contactView.leftButton.addTarget(self, action: #selector(ContactsViewController.leftButtonPressed(_:)), for: [UIControlEvents.touchUpInside])
        cell.contactView.rightButton.addTarget(self, action: #selector(ContactsViewController.rightButtonPressed(_:)), for: [UIControlEvents.touchUpInside])

        return cell
    }
    
    // MARK: - Contact Card Actions
    
    func leftButtonPressed(_ sender: UIButton) {
        let phoneNumber = AYNModel.sharedInstance.contactsArr[sender.tag].phoneNumber!
        print("Left button pressed -- row: \(sender.tag) -- Calling: \(phoneNumber) \n")
        
        let url: URL = URL(string: "tel://\(phoneNumber)")!
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func rightButtonPressed(_ sender: UIButton) {
        print("Right button pressed -- row: \(sender.tag)")
        performSegue(withIdentifier: "contactDetailMessage", sender: sender)
    }
    
    // Add label if table data array empty
    func checkCollectionViewEmpty() {
        if AYNModel.sharedInstance.contactsArr.isEmpty {
            let emptyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            emptyLabel.text = "Where is everyone?"
            emptyLabel.font = UIFont(name: "OpenSans-Semibold", size: 20)
            emptyLabel.textColor = slateBlue
            emptyLabel.isHidden = false
            emptyLabel.alpha = 1
            emptyLabel.textAlignment = NSTextAlignment.center
            
            self.contactsCollectionView.backgroundView = emptyLabel
        } else {
            self.contactsCollectionView.backgroundView = nil
        }
    }
    
    // MARK: - Refresh control
    func configureRefreshControl() {
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: slateBlue, NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 16)!])
        refreshControl.tintColor = slateBlue
        refreshControl.addTarget(self, action: #selector(ContactsViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        contactsCollectionView.addSubview(refreshControl)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "contactDetail" {
            let detailNavController: UINavigationController = segue.destination as! UINavigationController
            if self.contactsCollectionView.indexPathsForSelectedItems?.count > 0 {
                if let indexPath = self.contactsCollectionView.indexPathsForSelectedItems![0] as IndexPath? {
                    let contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]
                    if let cell = self.contactsCollectionView.cellForItem(at: indexPath) as? ContactCollectionViewCell {
                        if let detailVC: ContactDetailViewController = detailNavController.childViewControllers[0] as? ContactDetailViewController {
                            detailVC.contact = contact
                            detailVC.profileImage = cell.contactView.contactImageView.image
                        }
                    }
                }
            }
        } else if segue.identifier == "contactDetailMessage" {
            let detailNavController: UINavigationController = segue.destination as! UINavigationController
            if let indexPath = IndexPath(item: (sender! as AnyObject).tag, section: 0) as IndexPath? {
                let contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]
                if let cell = self.contactsCollectionView.cellForItem(at: indexPath) as? ContactCollectionViewCell {
                    if let detailVC: ContactDetailViewController = detailNavController.childViewControllers[0] as? ContactDetailViewController {
                        detailVC.contact = contact
                        detailVC.profileImage = cell.contactView.contactImageView.image
                        
                        detailVC.messageContact = true
                    }
                }
            }
        }
    }

}
