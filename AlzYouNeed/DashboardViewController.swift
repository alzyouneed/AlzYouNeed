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
        
//        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
//            if let currentUser = user {
//                // User is signed in.
//                print("\(currentUser) is logged in")
//            } else {
//                // No user is signed in.
//                print("No user is signed in")
//            }
//        }
    }
    
    override func viewDidAppear(animated: Bool) {
        let now = NSDate()
        dateView.configureView(now)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func logout(sender: UIBarButtonItem) {
        try! FIRAuth.auth()?.signOut()
    }
    

}
