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
        // Delete user
        let user = FIRAuth.auth()?.currentUser
        
        user?.deleteWithCompletion({ (error) in
            if let error = error {
                print("Error occurred while deleting account: \(error)")
            }
            else {
                print("Account deleted")
                self.performSegueWithIdentifier("startOverFamily", sender: self)
            }
        })
        // Clean up partially finished account creation entries
        deleteUserFromRealTimeDatabase()
        deletePictureFromDatabase()
    }
    
    func deletePictureFromDatabase() {
        if let user = FIRAuth.auth()?.currentUser {
            let storage = FIRStorage.storage()
            let storageRef = storage.reference()
            
            let userImageRef = storageRef.child("userImages/\(user.uid)")
            
            userImageRef.deleteWithCompletion({ (error) in
                if (error != nil) {
                    print("Error deleting file: \(error)")
                }
                else {
                    print("File deleted successfully")
                }
            })
        }
    }
    
    func deleteUserFromRealTimeDatabase() {
        if let user = FIRAuth.auth()?.currentUser {
            print("Deleting user from realtime DB")
            
            let databaseRef = FIRDatabase.database().reference()
            databaseRef.child("users/\(user.uid)").removeValue()
        }
    }
    
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
