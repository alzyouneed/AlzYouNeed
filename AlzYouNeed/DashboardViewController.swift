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
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let currentUser = user {
                // User is signed in.
                print("\(currentUser) is logged in")
//                // Check if current user has completed signup
//                FirebaseManager.getUserSignUpStatus({ (status, error) in
//                    if error == nil {
//                        if let status = status {
//                            switch status {
//                            case "updateUser":
//                                self.presentUpdateUserVC()
//                            case "familySetup":
//                                self.presentFamilyVC()
//                            default:
//                                break
//                                
//                            }
//                        }
//                    }
//                })
                
            }
            else {
                // No user is signed in.
                print("No user is signed in -- moving to onboarding flow")
                self.presentOnboardingVC()
            }
        }
        
        configureNavBarTitle()
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
        
        let updateAction = UIAlertAction(title: "Update Profile", style: .Default) { (action) in
            self.presentUpdateProfileVC()
        }
        let logoutAction = UIAlertAction(title: "Logout", style: .Default) { (action) in
            try! FIRAuth.auth()?.signOut()
            self.updateTabBadge()
        }
        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .Destructive) { (action) in
            self.showDeleteAccountWarning()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(logoutAction)
        alertController.addAction(deleteAccountAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showDeleteAccountWarning() {
        let alertController = UIAlertController(title: "Delete Account", message: "This cannot be undone", preferredStyle: .ActionSheet)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .Destructive) { (action) in
            FirebaseManager.deleteCurrentUser({ (error) in
                if error == nil {
                    // Success
                }
                else {
                    // Error
                    // Check for relevant error before showing alert
                    if error?.code != 2 && error?.code != 17011 {
                        print("Error deleting user: \(error)")
                        self.showLoginAlert()
                    }
                }
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func presentUpdateProfileVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let updateProfileVC: UpdateProfileViewController = storyboard.instantiateViewControllerWithIdentifier("updateProfile") as! UpdateProfileViewController
        
        // Hide tab bar in updateProfileVC
        updateProfileVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateProfileVC, animated: true)
    }
    
    func showLoginAlert() {
        let alert = UIAlertController(title: "Sign-in Required", message: "Please sign in to complete this action", preferredStyle: UIAlertControllerStyle.Alert)
        
        var emailTF: UITextField!
        var passwordTF: UITextField!
        alert.addTextFieldWithConfigurationHandler { (emailTextField) in
            emailTextField.placeholder = "Email"
            emailTextField.autocapitalizationType = UITextAutocapitalizationType.None
            emailTextField.autocorrectionType = UITextAutocorrectionType.No
            emailTextField.spellCheckingType = UITextSpellCheckingType.No
            emailTextField.keyboardType = UIKeyboardType.EmailAddress
            emailTF = emailTextField
        }
        alert.addTextFieldWithConfigurationHandler { (passwordTextField) in
            passwordTextField.placeholder = "Password"
            passwordTextField.autocapitalizationType = UITextAutocapitalizationType.None
            passwordTextField.autocorrectionType = UITextAutocorrectionType.No
            passwordTextField.spellCheckingType = UITextSpellCheckingType.No
            passwordTextField.keyboardType = UIKeyboardType.ASCIICapable
            passwordTextField.secureTextEntry = true
            passwordTF = passwordTextField
        }
        
        let confirmAction = UIAlertAction(title: "Login", style: .Default) { (action) in
            FIRAuth.auth()?.signInWithEmail(emailTF.text!, password: passwordTF.text!, completion: { (user, error) in
                if error == nil {
                    print("Login successful - showing delete account warning")
                    self.showDeleteAccountWarning()
                }
                else {
                    print("Error logging in: \(error)")
                    self.showLoginAlert()
                }
            })
        }
        
        alert.addAction(confirmAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Present different VC's
    func presentOnboardingVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("onboardingNav") as! UINavigationController
        self.presentViewController(onboardingVC, animated: true, completion: nil)
    }
    
    func presentFamilyVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: NewExistingFamilyViewController = storyboard.instantiateViewControllerWithIdentifier("familyVC") as! NewExistingFamilyViewController
        let navController = UINavigationController(rootViewController: onboardingVC)
        self.presentViewController(navController, animated: true, completion: nil)
        
    }
    
    func presentUpdateUserVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let updateUserVC: UpdateUserViewController = storyboard.instantiateViewControllerWithIdentifier("updateUserVC") as! UpdateUserViewController
        let navController = UINavigationController(rootViewController: updateUserVC)
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    func updateTabBadge() {
        let tabArray = tabBarController!.tabBar.items as NSArray!
        let tabItem = tabArray.objectAtIndex(2) as! UITabBarItem
        tabItem.badgeValue = nil
    }
    
    func configureNavBarTitle() {
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userDict = userDict {
                    if let userName = userDict.objectForKey("name") as? String {
                        self.navigationItem.title = userName
                    }
                }
            }
        }
    }
}
