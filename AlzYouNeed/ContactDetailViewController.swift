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

class ContactDetailViewController: UIViewController, UITableViewDelegate, MessageTableViewCellDelegate {

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
    
    @IBOutlet var tableViewTopConstraint: NSLayoutConstraint!
    
    var messageMode = false
    
    // Handle segue to message the contact
    var messageContact = false
    
    func configureView() {
        messagesTableView.delegate = self
        
        userView.userNameLabel.text = "\(contact.fullName!)"
        userView.setImage(profileImage)

        userView.view.backgroundColor = caribbeanGreen
        
        configureActionButtons()
        lastCalledLabel.isHidden = true
        
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
        contactActionButtons.leftButton.setTitle("Call", for: UIControlState())
        contactActionButtons.leftButton.backgroundColor = slateBlue
//        contactActionButtons.rightButton.setTitle("Locate", forState: UIControlState.Normal)
//        contactActionButtons.rightButton.backgroundColor =
        
        // TODO: Change later to add functionality
        contactActionButtons.singleButton("left")
        
        // Add targets
        contactActionButtons.leftButton.addTarget(self, action: #selector(ContactDetailViewController.leftButtonPressed(_:)), for: [UIControlEvents.touchUpInside])
    }
    
    func configureLastCalledLabel(_ dateString: String) {
        let date = Date(timeIntervalSince1970: Double(dateString)!)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM d, h:mm a"
        lastCalledLabel.text = "Last called: \(dateFormatter.string(from: date))"
        lastCalledLabel.isHidden = false
    }
    
    func hideExtraUserViewItems() {
        userView.familyGroupLabel.isHidden = true
        userView.separatorView.isHidden = true
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
                    if let lastCalled = userInfo.value(forKey: "lastCalled") as? String {
                        self.configureLastCalledLabel(lastCalled)
                    }
                }
            }
        }
        
        // Get conversation ID
//        if let userFamilyId = AYNModel.sharedInstance.currentUserFamilyId as String? {
        
        if let userFamilyId = AYNModel.sharedInstance.currentUser?.object(forKey: "familyId") as? String {
            FirebaseManager.getConversationId(userFamilyId, receiverId: contact.userId) { (error, conversationId) in
                if error == nil {
                    if let conversationId = conversationId {
                        self.conversationId = conversationId
                        self.addConversationObservers()
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(ContactDetailViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ContactDetailViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ContactDetailViewController.keyboardDidChangeFrame(_:)), name:UIKeyboardDidChangeFrameNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
//        addConversationObservers()
        if messageContact {
            messageTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
//        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardDidChangeFrameNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        removeConversationObservers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Action Buttons
    func leftButtonPressed(_ sender: UIButton) {
        print("Calling: \(contact.phoneNumber!)")
        
        // Save action in Firebase RTDB
        let now = Date().timeIntervalSince1970
        let updates = ["lastCalled": now.description]
        FirebaseManager.updateFamilyMemberUserInfo(contact.userId, updates: updates as NSDictionary) { (error) in
            if error == nil {
                // Success -- configure label
                self.configureLastCalledLabel(now.description)
            }
        }
        
        let url: URL = URL(string: "tel://\(contact.phoneNumber!)")!
//        UIApplication.shared.openURL(url)
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @IBAction func closeContactDetailView(_ sender: AnyObject) {
        self.view.endEditing(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Messaging
    @IBAction func sendMessage(_ sender: UIButton) {
        guard !messageTextField.text!.isEmpty else {
            print("Empty message textField")
            return
        }
        guard !conversationId.isEmpty else {
            print("No conversation ID")
            return
        }
        
        let newMessage = ["timestamp" : Date().timeIntervalSince1970.description, "messageString" : messageTextField.text!]
        sender.isEnabled = false
        
        FirebaseManager.sendNewMessage(contact.userId, conversationId: conversationId, message: newMessage as NSDictionary) { (error) in
            if error != nil {
                // Error
                sender.isEnabled = true
            } else {
                // Success
                self.messageTextField.text = ""
                sender.isEnabled = true
            }
        }
    }
    
    // MARK: - Firebase Observers
    func addConversationObservers() {
        print("Adding Firebase observers")
        if AYNModel.sharedInstance.currentUser != nil {
            if let userFamilyId = AYNModel.sharedInstance.currentUser?.value(forKey: "familyId") as? String {
                self.familyId = userFamilyId
                
                self.databaseRef.child("families").child(userFamilyId).child("conversations").child(self.conversationId).observe(.childAdded, with: { (snapshot) in
//                    self.databaseRef.child("families").child(userFamilyId).child("conversations").child(self.conversationId).queryLimitedToLast(50).observeEventType(.ChildAdded, withBlock: { (snapshot) in
                    var indexPaths: [IndexPath] = []
                    self.databaseRef.child("families").child(userFamilyId).child("conversations").child(self.conversationId).child(snapshot.key).observe(.value, with: { (snapshot) in
                        //                            print("Value: \(snapshot.value)")
                        if let newMessage = Message(messageId: snapshot.key, messageDict: snapshot.value as! NSDictionary) {
                            self.messages.append(newMessage)
                            indexPaths.append(IndexPath(row: self.messages.count-1, section: 0))
                            
                            //                                print("inserting new message into row")
                            self.messagesTableView.insertRows(at: indexPaths, with: .none)
                            
                            //                                self.messagesTableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
                            
                            DispatchQueue.main.async(execute: {
                                self.messagesTableView.scrollToRow(at: indexPaths.last!, at: .bottom, animated: false)
                            })
                        }
                    })
                })
            }
        }
    }
    
    func removeConversationObservers() {
        print("Removing Firebase observers")
        self.databaseRef.child("families").child(familyId).child("conversations").child(conversationId).removeAllObservers()
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        
        let message = messages[(indexPath as NSIndexPath).row]
        
        if message.senderId == FIRAuth.auth()?.currentUser?.uid {
            let cell:MessageTableViewCell = tableView.dequeueReusableCell(withIdentifier: "messageCellMe")! as! MessageTableViewCell
            cell.configureCell(message, contact: contact, profileImage: profileImage)
            cell.delegate = self
            return cell
        } else {
            let cell:MessageTableViewCell = tableView.dequeueReusableCell(withIdentifier: "messageCellYou")! as! MessageTableViewCell
            cell.configureCell(message, contact: contact, profileImage: profileImage)
            cell.delegate = self
            return cell
        }
    }
    
    // MARK: - MessageTableViewCell Delegate
    func cellButtonTapped(_ cell: MessageTableViewCell) {

        let indexPath = self.messagesTableView.indexPathForRow(at: cell.center)!
        print("Favorite selected at: \((indexPath as NSIndexPath).row)")
//        if let selectedMessage = messages[indexPath.row] as Message? {
//            // Favorite / Un-Favorite message
//            
//            var favorited = "true"
//            if cell.favoriteButton.selected == true {
//                // Already favorited -- un-favorite
//                print("Un-favoriting message")
//                favorited = "false"
//            }
//            
//            FirebaseManager.favoriteMessage(self.conversationId, messageId: selectedMessage.messageId, favorited: favorited, completionHandler: { (error) in
//                if let error = error {
//                    // Error
//                } else {
//                    // Success
////                    self.messages.removeAtIndex(indexPath.row)
////                    self.messagesTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .None)
//                }
//            })
//        }
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(_ show: Bool, notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue 
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
        if show {
            self.toolbarBottomConstraint.constant = changeInHeight
            scrollToBottom()
        } else {
            self.toolbarBottomConstraint.constant = 0
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShow(_ sender: Notification) {
        adjustingKeyboardHeight(true, notification: sender)
        configureMessageMode()
    }
    
    func keyboardWillHide(_ sender: Notification) {
        adjustingKeyboardHeight(false, notification: sender)
        configureMessageMode()
    }
    
//    func keyboardDidChangeFrame(sender: NSNotification) {
//        print("Keyboard frame did change")
//        adjustingKeyboardHeight(false, changeFrame: true, notification: sender)
//    }
    
    func configureHideKeyboard() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ContactDetailViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func scrollToBottom() {
        
//        if self.messagesTableView.contentSize.height > CGRectGetHeight(self.messagesTableView.frame) {
//            let contentOffset = CGPointMake(0, self.messagesTableView.contentSize.height - CGRectGetHeight(self.messagesTableView.frame))
//            self.messagesTableView.setContentOffset(contentOffset, animated: true)
//        }
        
        let lastRow = messagesTableView.numberOfRows(inSection: 0) - 1
        
        if lastRow >= 0 {
            messagesTableView.scrollToRow(at: IndexPath(row: lastRow, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
        }
    }
    
    func moveToLastMessage() {
        if self.messagesTableView.contentSize.height > self.messagesTableView.frame.height {
            print("Moving to last message")
//            let contentOffset = CGPointMake(0, self.messagesTableView.contentSize.height - CGRectGetHeight(self.messagesTableView.frame))
            let contentOffset = CGPoint(x: 0, y: self.messagesTableView.contentSize.height)
            self.messagesTableView.setContentOffset(contentOffset, animated: true)
        }
    }
    
    func configureMessageMode() {
        if !messageMode {
            messageMode = true

            self.navigationItem.title = "Messages"
            self.tableViewTopConstraint.constant = -100
            self.tableViewTopConstraint.constant -= self.userView.frame.height

            UIView.animate(withDuration: 0.2, animations: { 
                self.contactActionButtons.alpha = 0
                self.lastCalledLabel.alpha = 0
                self.view.layoutIfNeeded()
            })
        } else {
            messageMode = false
            
            self.navigationItem.title = nil
            self.tableViewTopConstraint.constant = 8
            
            UIView.animate(withDuration: 0.2, animations: {
//                self.contactActionButtons.alpha = 1
//                self.lastCalledLabel.alpha = 1
                self.view.layoutIfNeeded()
            })
            UIView.animate(withDuration: 0.2, delay: 0.2, options: [], animations: {
                self.contactActionButtons.alpha = 1
                self.lastCalledLabel.alpha = 1
                }, completion: nil)
        }
    }
}
