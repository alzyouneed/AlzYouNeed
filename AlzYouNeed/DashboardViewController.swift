//
//  DashboardViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class DashboardViewController: UIViewController {
    
    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var dateView: DateDashboardView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        FirebaseManager.getUserSignUpStatus { (status, error) in
            if error == nil {
                if let signupStatus = status {
                    print("Sign up completed: \(signupStatus)")
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        let now = NSDate()
        dateView.configureView(now)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    @IBAction func showSettings(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .ActionSheet)
        let logoutAction = UIAlertAction(title: "Logout", style: .Default) { (action) in
            try! FIRAuth.auth()?.signOut()
        }
        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .Destructive) { (action) in
            FirebaseManager.deleteCurrentUser({ (error) in
                if error == nil {
                    // Success
                }
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(logoutAction)
        alertController.addAction(deleteAccountAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
}
