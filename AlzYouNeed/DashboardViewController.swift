//
//  DashboardViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class DashboardViewController: UIViewController {
    
    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var dateView: DateDashboardView!
    @IBOutlet var dashboardActionButtons: actionButtonsDashboardView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
//            if let currentUser = user {
            if let currentUser = FIRAuth.auth()?.currentUser {
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
        
        configureView()
        
//        let newMessage = ["timestamp" : NSDate().timeIntervalSince1970.description, "messageString" : "Want to hangout today?"]
//        FirebaseManager.sendNewMessage("79nSgKxgI4QVcSMkavYYc7WUs7v2", message: newMessage) { (error) in
//            if error == nil {
////                print("Message sent")
//            }
//        }
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        self.tabBarController?.tabBar.layer.borderWidth = 0.5
        self.tabBarController?.tabBar.layer.borderColor = UIColor.lightGrayColor().CGColor
        
        // If new user signed in -- force reload view
        if AYNModel.sharedInstance.wasReset {
            print("Model was reset -- reseting UI")
            configureView()
        }
        else if AYNModel.sharedInstance.profileWasUpdated {
            print("Profile was udpated -- resetting UI")
            AYNModel.sharedInstance.profileWasUpdated = false
            configureView()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        let now = NSDate()
        dateView.configureView(now)
        
        if self.navigationItem.title == "" {
            configureUserNameLabel()
        }
    }
    
//    override func viewDidDisappear(animated: Bool) {
//        self.navigationController?.hideTransparentNavBar()
//    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    @IBAction func showSettings(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .ActionSheet)
        
        let updateAction = UIAlertAction(title: "Update Profile", style: .Default) { (action) in
            self.presentUpdateProfileVC()
        }
        let pushNotificationsAction = UIAlertAction(title: "Push Notifications", style: .Default) { (action) in
            if let appSettings = NSURL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.sharedApplication().openURL(appSettings)
            }
        }
        let logoutAction = UIAlertAction(title: "Logout", style: .Default) { (action) in
            // Clean up current session
            AYNModel.sharedInstance.resetModel()
            self.updateTabBadge()
            self.resetView()
            print("User logged out")
            try! FIRAuth.auth()?.signOut()
        }
        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .Destructive) { (action) in
            self.showDeleteAccountWarning()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(pushNotificationsAction)
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
    
    func resetView() {
        self.navigationItem.title = ""
        self.userView.userImageView.image = nil
    }
    
    // MARK: - Configuration
    func configureView() {
        configureUserNameLabel()
        configureActionButtons()
    }
    
    func configureUserNameLabel() {
        print("Configure nav bar title")
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userDict = userDict {
                    if let userName = userDict.objectForKey("name") as? String {
                        dispatch_async(dispatch_get_main_queue(), { 
                            self.userView.userNameLabel.text = userName
                        })
//                        self.userView.userNameLabel.text = userName
                        
                        if let photoUrl = userDict.objectForKey("photoUrl") as? String {
                            self.configureDashboardView(photoUrl)
                        }
                    }
                }
            }
        }
    }
    
    func configureDashboardView(imageUrl: String) {
            if imageUrl.hasPrefix("gs://") {
                FIRStorage.storage().referenceForURL(imageUrl).dataWithMaxSize(INT64_MAX, completion: { (data, error) in
                    if let error = error {
                        // Error
                        print("Error downloading user profile image: \(error.localizedDescription)")
                        return
                    }
                    // Success
                    if let image = UIImage(data: data!) as UIImage? {
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            self.userView.setImage(image)
                        })
                        // Reset variable only after configuration is complete
                        AYNModel.sharedInstance.wasReset = false
                    }
                })
            } else if let url = NSURL(string: imageUrl), data = NSData(contentsOfURL: url) {
                if let image = UIImage(data: data) as UIImage? {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.userView.setImage(image)
                    })
                    // Reset variable only after configuration is complete
                    AYNModel.sharedInstance.wasReset = false
                }
            }
    }
    
    func configureActionButtons() {
        // TODO: Change later to add functionality
        dashboardActionButtons.singleButton("left")
    }
    
}
