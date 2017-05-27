//
//  ContactsViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 7/22/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import MessageUI
import PKHUD

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


class ContactsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    // MARK: - UI Elements
    @IBOutlet var contactsCollectionView: UICollectionView!
    var refreshControl: UIRefreshControl!
    @IBOutlet var searchBar: UISearchBar!
    var filteredContacts: [Contact] = []
    var searchActive = false
    
    @IBOutlet var emergencyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        DispatchQueue.main.async {
            self.contactsCollectionView.reloadData()
            self.checkCollectionViewEmpty()
//        }
        
//         print("ContactsArr: \(AYNModel.sharedInstance.contactsArr)")
        
//        self.contactsCollectionView.reloadData()
//        self.checkCollectionViewEmpty()
        
        configureRefreshControl()
//        loadContacts(false)
        contactsCollectionView.delegate = self
        contactsCollectionView.dataSource = self
        searchBar.delegate = self
        
        checkTutorialStatus()
        configureEmergencyButton()
        
//        PKHUD.sharedHUD.userInteractionOnUnderlyingViewsEnabled = true
//        testLoadContacts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        // If new user signed in -- force reload contacts
        if AYNModel.sharedInstance.contactsArrWasReset {
            AYNModel.sharedInstance.contactsArrWasReset = false
            print("Model was reset -- loading contacts")
            loadContacts(false)
        }
        
        if !(searchBar.text!.isEmpty) {
            searchActive = true
            searchBar.becomeFirstResponder()
        } else {
            searchActive = false
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
            HUD.show(.progress)
        }
        
        FirebaseManager.getFamilyMembers { (members, error) in
            if error == nil {
                if let members = members {
                    HUD.hide()
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
                 HUD.hide()
            }
        }
    }
    
    func testLoadContacts() {
        var members: [Contact] = []
        
        FirebaseManager.getFamilyMembers { (familyMembers, error) in
            if error == nil {
                if let familyMembers = familyMembers {
                    print("TEST - GOT FAMILY MEMBERS")
                    members = familyMembers
                    
//                    let queue = DispatchQueue(label: "com.AlzYouNeed.gcd", attributes: .concurrent, target: .main)
                    
                    
//                    queue.async {
                        for member in members {
                            print("TEST - Starting async lookup of user in family: \(member.name)")
                            FirebaseManager.getUserById(member.userId, completionHandler: { (userDict, error) in
                                if error == nil {
                                    if let userDict = userDict {
                                        print("TEST - Retrieved user: \(userDict)")
                                    }
                                }
                            })
//                        }
                    }
                }
            }
        }
        

//        let queue = DispatchQueue(label: "com.AlzYouNeed.gcd", attributes: .concurrent, target: .main)
//        
//        
//        queue.sync {
//            for member in members {
//                print("TEST - Starting async lookup of user in family: \(member.fullName)")
//                FirebaseManager.getUserById(member.userId, completionHandler: { (userDict, error) in
//                    if error == nil {
//                        if let userDict = userDict {
//                            print("TEST - Retrieved user: \(userDict)")
//                        }
//                    }
//                })
//            }
//        }
        
        
    }
    
    func refresh(_ control: UIRefreshControl) {
        print("Refreshing")
        loadContacts(true)
    }
    
    // MARK: - UICollectionViewDataSource
    
    @objc(numberOfSectionsInCollectionView:) func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchActive {
            return filteredContacts.count
        } else {
            return AYNModel.sharedInstance.contactsArr.count
        }
    }
    
    @objc(collectionView:cellForItemAtIndexPath:) func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContactCell", for: indexPath) as! ContactCollectionViewCell
        
        let contact: Contact

        if searchActive {
            contact = filteredContacts[indexPath.row]
        } else {
            contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]
        }

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
                    let contact: Contact
                    if searchActive {
                        contact = filteredContacts[(indexPath as NSIndexPath).row]
                    } else {
                        contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]
                    }
                    
//                    let contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]
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
                let contact: Contact
                if searchActive {
                    contact = filteredContacts[(indexPath as NSIndexPath).row]
                } else {
                    contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]
                }
                
//                let contact = AYNModel.sharedInstance.contactsArr[(indexPath as NSIndexPath).row]
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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.searchBar.resignFirstResponder()
        self.searchBar.endEditing(true)
        print("touch")
    }
}

extension ContactsViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if searchBar.text!.isEmpty {
            searchActive = false
        } else {
            searchActive = true
        }
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredContacts = AYNModel.sharedInstance.contactsArr.filter { $0.name.contains(searchText) }
        if filteredContacts.count == 0 {
            searchActive = false
        } else {
            searchActive = true
        }
        self.contactsCollectionView.reloadData()
    }
    
    // MARK: Tutorial
    func checkTutorialStatus() {
        if let contactListTutorialCompleted = UserDefaultsManager.getTutorialCompletion(tutorial: Tutorials.contactList.rawValue) as String? {
            if contactListTutorialCompleted == "false" {
                showTutorial()
            } else {
//                print("ContactList tutorial completed")
            }
        }
    }
    
    func showTutorial() {
        let alertController = UIAlertController(title: "Tutorial", message: "Family members will show up here. Call or message them, or tap on their card to see their profile.", preferredStyle: .alert)
        
        let completeAction = UIAlertAction(title: "Got it!", style: .default) { (action) in
            UserDefaultsManager.completeTutorial(tutorial: "contactList")
        }
        
        alertController.addAction(completeAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ContactsViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result.rawValue {
        case MessageComposeResult.cancelled.rawValue:
            print("Message cancelled")
        case MessageComposeResult.failed.rawValue:
            print("Message failed")
        case MessageComposeResult.sent.rawValue:
            print("Message sent")
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Emergency button
extension ContactsViewController {
    func configureEmergencyButton() {
        emergencyButton.backgroundColor = caribbeanGreen
        emergencyButton.layer.cornerRadius = emergencyButton.frame.width/2
        emergencyButton.layer.shadowRadius = 1
        emergencyButton.layer.shadowColor = UIColor.black.cgColor
        emergencyButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        emergencyButton.layer.shadowOpacity = 0.5
        
        emergencyButton.addTarget(self, action: #selector(ContactsViewController.emergencyButtonPressed(_:)), for: [.touchUpInside, .touchDown])
        
        if !AYNModel.sharedInstance.familyMemberNumbers.isEmpty {
            self.emergencyButton.isHidden = false
            self.emergencyButton.isEnabled = true
        }
    }
    
    func emergencyButtonPressed(_ sender: UIButton) {
        print("Group chat button pressed")
        let messageVC = MFMessageComposeViewController()
//        messageVC.body = "EMERGENCY: I need help now!"
        messageVC.recipients = AYNModel.sharedInstance.familyMemberNumbers
        messageVC.messageComposeDelegate = self
        present(messageVC, animated: true, completion: nil)
    }
    
}
