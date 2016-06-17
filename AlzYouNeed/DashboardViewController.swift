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
//        UserDefaultsManager.logout()
        
        try! FIRAuth.auth()?.signOut()
        
//        self.parentViewController?.performSegueWithIdentifier("Logout", sender: self)
//        self.performSegueWithIdentifier("Logout", sender: self)
        self.navigationController?.performSegueWithIdentifier("Logout", sender: self)
//        self.parentViewController?.parentViewController?.performSegueWithIdentifier("Onboarding", sender: self)
        
//        let next = self.storyboard?.instantiateViewControllerWithIdentifier("OnboardingVC") as! OnboardingViewController
//        self.tabBarController!.presentViewController(next, animated: true, completion: nil)
        
//        let topVC = UIApplication.sharedApplication().keyWindow?.rootViewController
//        topVC?.performSegueWithIdentifier("Onboarding", sender: self)
        
//        self.performSegueWithIdentifier("Logout", sender: self)
        
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let onboardingVC = storyboard.instantiateViewControllerWithIdentifier("OnboardingVC") as! OnboardingViewController
//        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
//        appDelegate.window?.rootViewController = onboardingVC
//
////        self.showDetailViewController(onboardingVC, sender: self)
//        
//        UIView.transitionWithView(appDelegate.window!, duration: 0.5, options: UIViewAnimationOptions.TransitionFlipFromRight, animations: {
//            appDelegate.window?.rootViewController = onboardingVC
//            }, completion: nil)
    }
    

}
