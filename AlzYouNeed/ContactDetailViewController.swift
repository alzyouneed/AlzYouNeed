//
//  ContactDetailViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/13/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Contacts

class ContactDetailViewController: UIViewController {

    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var contactActionButtons: actionButtonsDashboardView!
    var contact: Contact!
    
    func configureView() {
        
        userView.userNameLabel.text = "\(contact.fullName)"
        if let image = UIImage(named: contact.avatarId) as UIImage? {
            userView.setImage(image)
        }
        
        userView.view.backgroundColor = caribbeanGreen
        
        configureActionButtons()

//        contactCard.leftButton.addTarget(self, action: #selector(ContactDetailViewController.leftButtonPressed(_:)), forControlEvents: [UIControlEvents.TouchUpInside])
        
        // Check if saved image to load
//        if let imagePhotoPath = person.photoPath {
//            contactCard.setImageWithPath(imagePhotoPath)
//        }
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

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configureView()
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
        
        let url: NSURL = NSURL(string: "tel://\(contact.phoneNumber)")!
        UIApplication.sharedApplication().openURL(url)
    }
    
    @IBAction func closeContactDetailView(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}
