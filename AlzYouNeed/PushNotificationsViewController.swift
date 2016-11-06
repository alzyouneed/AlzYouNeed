//
//  PushNotificationsViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 8/4/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class PushNotificationsViewController: UIViewController {
    
    @IBOutlet var progressView: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            self.progressView.setProgress(0.5, animated: true)
        }) 
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        self.navigationItem.hidesBackButton = true
    }
    
    @IBAction func enablePush(_ sender: UIButton) {
        // TODO: Perform segue after user has clicked "Allow"
//        registerPushNotifications()
        performSegue(withIdentifier: "familyStage", sender: self)
    }
    
    @IBAction func disablePush(_ sender: UIButton) {
        // Show alert with tip on how to enable later
        let alertController = UIAlertController(title: "Tip", message: "You can enable notifications in Settings if you change your mind", preferredStyle: .alert)
        let confirmAction = UIAlertAction(title: "Got it", style: .default) { (action) in
            // Transition to next step in onboarding
            self.performSegue(withIdentifier: "familyStage", sender: self)
        }
        let cancelAction = UIAlertAction(title: "I change my mind...", style: .cancel, handler: nil)
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
//    func registerPushNotifications() {
//        let settings: UIUserNotificationSettings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//        UIApplication.shared.registerUserNotificationSettings(settings)
//        UIApplication.shared.registerForRemoteNotifications()
//    }
    
    
    // MARK: - Cancel Onboarding
    @IBAction func cancelOnboarding(_ sender: UIBarButtonItem) {
        AYNModel.sharedInstance.onboarding = false
        cancelAccountCreation()
    }
    
    func cancelAccountCreation() {
        
        let alertController = UIAlertController(title: "Cancel Signup", message: "All progress will be lost", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
            self.deleteUser()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func deleteUser() {
        FirebaseManager.deleteCurrentUser { (error) in
            if error != nil {
                // Error deleting user
            }
            else {
                // Successfully deleted user
                let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//                let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "onboardingNav") as! UINavigationController
                let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
                self.present(onboardingVC, animated: true, completion: nil)
            }
        }
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
