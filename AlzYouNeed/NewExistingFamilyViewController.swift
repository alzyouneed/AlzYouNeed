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

    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet var cancelButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        UIView.animateWithDuration(0.5) {
            self.progressView.setProgress(0.66, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func cancelOnboarding(sender: UIBarButtonItem) {
        cancelAccountCreation()
    }
    
    // MARK: - Firebase
    func cancelAccountCreation() {
        
        let alertController = UIAlertController(title: "Cancel Signup", message: "All progress will be lost", preferredStyle: .ActionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive) { (action) in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func deleteUser() {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting user
            }
            else {
                // Successfully deleted user
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let onboardingVC: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("onboardingNav") as! UINavigationController
                self.presentViewController(onboardingVC, animated: true, completion: nil)
            }
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
