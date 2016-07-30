//
//  ContactDetailViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class ContactDetailViewController: UIViewController, UITableViewDelegate {

    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var contactActionButtons: actionButtonsDashboardView!
    @IBOutlet var lastCalledLabel: UILabel!
    
    var contact: Contact!
    var profileImage: UIImage!
    
    @IBOutlet var messageTextField: UITextField!
    
    let databaseRef = FIRDatabase.database().reference()
    var conversationId: String!
    var familyId: String!
    
    var messages: [Message] = []
    @IBOutlet var messagesTableView: UITableView!
    
    @IBOutlet var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var scrollView: UIScrollView!
    
    func configureView() {
        messagesTableView.delegate = self
        
        userView.userNameLabel.text = "\(contact.fullName)"
        userView.setImage(profileImage)

        userView.view.backgroundColor = caribbeanGreen
        
        configureActionButtons()
        lastCalledLabel.hidden = true
        
        // Check user type
        if let userIsAdmin = contact.admin as String? {
            if userIsAdmin == "true" {
                userView.specialUser("admin")
            } else {
                if let userIsPatient = contact.patient as String? {
                    if userIsPatient == "true" {
                        userView.specialUser("patient")
                    } else {
                        userView.specialUser("none")
                    }
                }
            }
        }
        
        // Hides redundant information
        hideExtraUserViewItems()
    }
    
    func configureActionButtons() {
        contactActionButtons.leftButton.setTitle("Call", forState: UIControlState.Normal)
        contactActionButtons.leftButton.backgroundColor = slateBlue
//        contactActionButtons.rightButton.setTitle("Locate", forState: UIControlState.Normal)
//        contactActionButtons.rightButton.backgroundColor =
        
        // TODO: Change later to add functionality
        contactActionButtons.singleButton("left")
        
        // Add targets
        contactActionButtons.leftButton.addTarget(self, action: #selector(ContactDetailViewController.leftButtonPressed(_:)), forControlEvents: [UIControlEvents.TouchUpInside])
    }
    
    func configureLastCalledLabel(dateString: String) {
        let date = NSDate(timeIntervalSince1970: Double(dateString)!)
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMMM d, h:mm a"
        lastCalledLabel.text = "Last called: \(dateFormatter.stringFromDate(date))"
        lastCalledLabel.hidden = false
    }
    
    func hideExtraUserViewItems() {
        userView.familyGroupLabel.hidden = true
        userView.separatorView.hidden = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.messages.removeAll()
        self.configureView()
        configureHideKeyboard()
        
        messagesTableView.estimatedRowHeight = 100
        messagesTableView.rowHeight = UITableViewAutomaticDimension
        
        // Get user info
        FirebaseManager.getFamilyMemberUserInfo(contact.userId) { (error, userInfo) in
            if error == nil {
                if let userInfo = userInfo {
//                    print("userInfo: \(userInfo)")
                    if let lastCalled = userInfo.valueForKey("lastCalled") as? String {
                        self.configureLastCalledLabel(lastCalled)
                    }
                }
            }
        }
        
        // Get conversation ID
        FirebaseManager.getConversationId(contact.userId) { (error, conversationId) in
            if error == nil {
                if let conversationId = conversationId {
                    self.conversationId = conversationId
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactDetailViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactDetailViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        addConversationObservers()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(animated: Bool) {
        removeConversationObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action Buttons
    func leftButtonPressed(sender: UIButton) {
        print("Calling: \(contact.phoneNumber)")
        
        // Save action in Firebase RTDB
        let now = NSDate().timeIntervalSince1970
        let updates = ["lastCalled": now.description]
        FirebaseManager.updateFamilyMemberUserInfo(contact.userId, updates: updates) { (error) in
            if error == nil {
                // Success -- configure label
                self.configureLastCalledLabel(now.description)
            }
        }
        
        let url: NSURL = NSURL(string: "tel://\(contact.phoneNumber)")!
        UIApplication.sharedApplication().openURL(url)
    }
    
    @IBAction func closeContactDetailView(sender: AnyObject) {
        self.view.endEditing(true)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - Messaging
    @IBAction func sendMessage(sender: UIButton) {
        guard !messageTextField.text!.isEmpty else {
            print("Empty message textField")
            return
        }
        
        let newMessage = ["timestamp" : NSDate().timeIntervalSince1970.description, "messageString" : messageTextField.text!]
        sender.enabled = false

        FirebaseManager.sendNewMessage(contact.userId, message: newMessage) { (error) in
            if error != nil {
                // Error
                sender.enabled = true
            } else {
                // Success
                self.messageTextField.text = ""
                sender.enabled = true
            }
        }
    }
    
    // MARK: - Firebase Observers
    func addConversationObservers() {
        print("Adding Firebase observers")
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userFamilyId = userDict?.valueForKey("familyId") as? String {
                    self.familyId = userFamilyId
                    
                    self.databaseRef.child("families").child(userFamilyId).child("conversations").child(self.conversationId).observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
                        
                        self.messages.removeAll()
                        for item in snapshot.children {
                            if let item = item as? FIRDataSnapshot {
                                //                                                print("Item -- key: \(item.key) -- value: \(item.value)")
                                if let newMessage = Message(messageId: item.key, messageDict: item.value as! NSDictionary) {
                                    self.messages.append(newMessage)
                                    self.messagesTableView.reloadData()
                                    
                                    //                                                    self.messagesTableView.insertRowsAtIndexPaths([NSIndexPath(forRow: self.messages.count-1, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
                                    //                                                    self.messagesTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: self.messages.count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
                                    
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        self.scrollToBottom()
                                    })
                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    func removeConversationObservers() {
        print("Removing Firebase observers")
        self.databaseRef.child("families").child(familyId).child("conversations").child(conversationId).removeAllObservers()
    }
    
    // MARK: - UITableViewDelegate
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:MessageTableViewCell = tableView.dequeueReusableCellWithIdentifier("messageCell")! as! MessageTableViewCell
        
        let message = messages[indexPath.row]

        cell.configureCell(message, contact: contact, profileImage: profileImage)
        
        return cell
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (CGRectGetHeight(keyboardFrame)) //* (show ? 1 : -1)
        
//        UIView.performWithoutAnimation({
//            self.nameVTFView.layoutIfNeeded()
//            self.phoneNumberVTFView.layoutIfNeeded()
//        })
        
        if show {
            self.toolbarBottomConstraint.constant = changeInHeight
            scrollViewBottomConstraint.constant = changeInHeight + 44
            
//            var offset = scrollView.contentOffset
//            offset.y = scrollView.contentSize.height - scrollView.contentInset.bottom + scrollView.bounds.size.height
            
            let bottomOffset: CGPoint = CGPointMake(0, changeInHeight)
            
            scrollView.setContentOffset(bottomOffset, animated: true)
        }
        else {
            self.toolbarBottomConstraint.constant = 0
            scrollViewBottomConstraint.constant = 0
        }
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(true, notification: sender)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(false, notification: sender)
    }
    
    func configureHideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContactDetailViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func scrollToBottom() {
        let lastRow = messagesTableView.numberOfRowsInSection(0) - 1
        
        if lastRow >= 0 {
            messagesTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: lastRow, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
        }
    }
    

}
