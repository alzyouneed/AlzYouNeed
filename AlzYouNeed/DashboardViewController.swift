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
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
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
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.presentTransparentNavBar()
        
        self.tabBarController?.tabBar.layer.borderWidth = 0.5
        self.tabBarController?.tabBar.layer.borderColor = UIColor.lightGray.cgColor
        
        // If new user signed in -- force reload view
        if AYNModel.sharedInstance.wasReset {
            print("Model was reset -- reseting UI")
            configureView()
        }
        else if AYNModel.sharedInstance.profileWasUpdated {
            print("Profile was updated -- resetting UI")
            AYNModel.sharedInstance.profileWasUpdated = false
            configureView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let now = Date()
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

    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        
        let updateAction = UIAlertAction(title: "Update Profile", style: .default) { (action) in
            self.presentUpdateProfileVC()
        }
//        let pushNotificationsAction = UIAlertAction(title: "Push Notifications", style: .default) { (action) in
//            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
////                UIApplication.shared.openURL(appSettings)
//                
//                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
//            }
//        }
        let logoutAction = UIAlertAction(title: "Logout", style: .default) { (action) in
            // Clean up current session
            AYNModel.sharedInstance.resetModel()
            self.updateTabBadge()
            self.resetView()
            print("User logged out")
            try! FIRAuth.auth()?.signOut()
        }
        let deleteAccountAction = UIAlertAction(title: "Delete Account", style: .destructive) { (action) in
            self.showDeleteAccountWarning()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(updateAction)
//        alertController.addAction(pushNotificationsAction)
        alertController.addAction(logoutAction)
        alertController.addAction(deleteAccountAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func showDeleteAccountWarning() {
        let alertController = UIAlertController(title: "Delete Account", message: "This cannot be undone", preferredStyle: .actionSheet)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .destructive) { (action) in
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
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func presentUpdateProfileVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let updateProfileVC: UpdateProfileViewController = storyboard.instantiateViewController(withIdentifier: "updateProfile") as! UpdateProfileViewController
        
        // Hide tab bar in updateProfileVC
        updateProfileVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateProfileVC, animated: true)
    }
    
    func showLoginAlert() {
        let alert = UIAlertController(title: "Sign-in Required", message: "Please sign in to complete this action", preferredStyle: UIAlertControllerStyle.alert)
        
        var emailTF: UITextField!
        var passwordTF: UITextField!
        alert.addTextField { (emailTextField) in
            emailTextField.placeholder = "Email"
            emailTextField.autocapitalizationType = UITextAutocapitalizationType.none
            emailTextField.autocorrectionType = UITextAutocorrectionType.no
            emailTextField.spellCheckingType = UITextSpellCheckingType.no
            emailTextField.keyboardType = UIKeyboardType.emailAddress
            emailTF = emailTextField
        }
        alert.addTextField { (passwordTextField) in
            passwordTextField.placeholder = "Password"
            passwordTextField.autocapitalizationType = UITextAutocapitalizationType.none
            passwordTextField.autocorrectionType = UITextAutocorrectionType.no
            passwordTextField.spellCheckingType = UITextSpellCheckingType.no
            passwordTextField.keyboardType = UIKeyboardType.asciiCapable
            passwordTextField.isSecureTextEntry = true
            passwordTF = passwordTextField
        }
        
        let confirmAction = UIAlertAction(title: "Login", style: .default) { (action) in
            FIRAuth.auth()?.signIn(withEmail: emailTF.text!, password: passwordTF.text!, completion: { (user, error) in
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
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Present different VC's
    func presentOnboardingVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "onboardingNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }
    
    func presentFamilyVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: NewExistingFamilyViewController = storyboard.instantiateViewController(withIdentifier: "familyVC") as! NewExistingFamilyViewController
        let navController = UINavigationController(rootViewController: onboardingVC)
        self.present(navController, animated: true, completion: nil)
        
    }
    
    func presentUpdateUserVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let updateUserVC: UpdateUserViewController = storyboard.instantiateViewController(withIdentifier: "updateUserVC") as! UpdateUserViewController
        let navController = UINavigationController(rootViewController: updateUserVC)
        self.present(navController, animated: true, completion: nil)
    }
    
    func updateTabBadge() {
        let tabArray = tabBarController!.tabBar.items as NSArray!
        let tabItem = tabArray?.object(at: 2) as! UITabBarItem
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
        //        print("Configure nav bar title")
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userDict = userDict {
                    if let userName = userDict.object(forKey: "name") as? String {
                        DispatchQueue.main.async(execute: {
                            self.userView.userNameLabel.text = userName
                        })
                        if let familyId = userDict.object(forKey: "familyId") as? String {
                            DispatchQueue.main.async(execute: {
                                self.userView.familyGroupLabel.text = familyId
                            })
                            AYNModel.sharedInstance.currentUserFamilyId = familyId
                            if let admin = userDict.object(forKey: "admin") as? String {
                                if admin == "true" {
                                    DispatchQueue.main.async(execute: {
                                        self.userView.specialUser("admin")
                                    })
                                } else {
                                    if let patient = userDict.object(forKey: "patient") as? String {
                                        if patient == "true" {
                                            DispatchQueue.main.async(execute: {
                                                self.userView.specialUser("patient")
                                            })
                                        } else {
                                            self.userView.specialUser("none")
                                        }
                                    }
                                }
                                
                                if let photoUrl = userDict.object(forKey: "photoUrl") as? String {
                                    self.configureDashboardView(photoUrl)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func configureDashboardView(_ imageUrl: String) {
            if imageUrl.hasPrefix("gs://") {
                FIRStorage.storage().reference(forURL: imageUrl).data(withMaxSize: INT64_MAX, completion: { (data, error) in
                    if let error = error {
                        // Error
                        print("Error downloading user profile image: \(error.localizedDescription)")
                        return
                    }
                    // Success
                    if let image = UIImage(data: data!) as UIImage? {
                        
                        DispatchQueue.main.async(execute: {
                            self.userView.setImage(image)
                        })
                        AYNModel.sharedInstance.currentUserProfileImage = image
                        // Reset variable only after configuration is complete
                        AYNModel.sharedInstance.wasReset = false
                    }
                })
            } else if let url = URL(string: imageUrl), let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) as UIImage? {
                    
                    DispatchQueue.main.async(execute: {
                        self.userView.setImage(image)
                    })
                    AYNModel.sharedInstance.currentUserProfileImage = image
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
