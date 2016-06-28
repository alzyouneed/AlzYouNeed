//
//  NewExistingFamilyViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class NewExistingFamilyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(NewExistingFamilyViewController.cancelAccountCreation(_:)))
    }
    
    // MARK: - Firebase
    func cancelAccountCreation(sender: UIBarButtonItem) {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting current user
            }
            else {
                // Successfully deleted current user
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("onboardingNav") as! UINavigationController
                self.presentViewController(onboardingVC, animated: true, completion: nil)
            }
        }
    }
    
//    func deletePictureFromDatabase() {
//        FirebaseManager.deletePictureFromDatabase { (error) in
//            if error != nil {
//                // Error deleting user picture from database
//            }
//            else {
//                // Successfully deleted user picture from database
//            }
//        }
//    }
    
//    func deleteUserFromRealTimeDatabase() {
//        FirebaseManager.deleteUserFromRealTimeDatabase { (error, databaseRef) in
//            if error != nil {
//                // Error deleting user from realTime database
//            }
//            else {
//                // Successfully deleted user from realTime database
//            }
//        }
//    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let destinationVC = segue.destinationViewController as? FamilySignupViewController {
            // New family
            if sender?.tag == 0 {
               destinationVC.newFamily = true
                
            }
            // Existing family
            else {
                destinationVC.newFamily = false
            }
        }
        
    }
 

}
