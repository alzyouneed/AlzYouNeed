//
//  UpdateUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class UpdateUserViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(UpdateUserViewController.cancelAccountCreation(_:)))
    }
    
    func cancelAccountCreation(sender: UIBarButtonItem) {
        // Delete user
        let user = FIRAuth.auth()?.currentUser
        
        user?.deleteWithCompletion({ (error) in
            if let error = error {
                print("Error occurred while deleting account: \(error)")
            }
            else {
                print("Account deleted")
                self.performSegueWithIdentifier("startOver", sender: self)
            }
        })
//        self.performSegueWithIdentifier("startOver", sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
