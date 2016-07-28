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

class ContactDetailViewController: UIViewController {

    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var contactActionButtons: actionButtonsDashboardView!
    @IBOutlet var lastCalledLabel: UILabel!
    
    var contact: Contact!
    var profileImage: UIImage!
    
    func configureView() {
        
        userView.userNameLabel.text = "\(contact.fullName)"
        userView.setImage(profileImage)

        userView.view.backgroundColor = caribbeanGreen
        
        configureActionButtons()
        lastCalledLabel.hidden = true
        
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
        
        self.configureView()
        
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
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
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
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
