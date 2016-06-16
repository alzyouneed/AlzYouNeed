//
//  DashboardViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class DashboardViewController: UIViewController {
    
    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var dateView: DateDashboardView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        let now = NSDate()
        dateView.configureView(now)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    @IBAction func logout(sender: UIBarButtonItem) {
        UserDefaultsManager.logout()
        self.performSegueWithIdentifier("Logout", sender: self)
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
