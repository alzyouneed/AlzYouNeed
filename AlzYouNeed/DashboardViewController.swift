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
import MessageUI

class DashboardViewController: UIViewController {
    
    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var dateView: DateDashboardView!
    @IBOutlet var dashboardActionButtons: actionButtonsDashboardView!
    @IBOutlet var reminderActionButtonView: actionButtonsDashboardView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkUserSignedIn()

        dashboardActionButtons.leftButton.addTarget(self, action: #selector(DashboardViewController.notepadButtonPressed(_:)), for: [UIControlEvents.touchUpInside])
        dashboardActionButtons.rightButton.addTarget(self, action: #selector(DashboardViewController.emergencyButtonPressed(_:)), for: [UIControlEvents.touchUpInside])
        
        reminderActionButtonView.leftButton.addTarget(self, action: #selector(DashboardViewController.reminderButtonPressed(_:)), for: [UIControlEvents.touchUpInside])
        
        configureView()
        self.navigationController?.presentTransparentNavBar()
        
        self.tabBarController?.tabBar.layer.borderWidth = 0.5
        self.tabBarController?.tabBar.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        self.navigationController?.presentTransparentNavBar()
//        
//        self.tabBarController?.tabBar.layer.borderWidth = 0.5
//        self.tabBarController?.tabBar.layer.borderColor = UIColor.lightGray.cgColor
        
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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }

    @IBAction func showSettings(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .actionSheet)
        
        let updateAction = UIAlertAction(title: "Update Profile", style: .default) { (action) in
            self.presentUpdateProfileVC()
        }
        let pushNotificationsAction = UIAlertAction(title: "Notifications", style: .default) { (action) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        }
        let logoutAction = UIAlertAction(title: "Logout", style: .default) { (action) in
            // Clean up current session
            AYNModel.sharedInstance.resetModel()
            self.updateTabBadge()
            self.resetView()
            print("User logged out")
            try! FIRAuth.auth()?.signOut()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            // Cancel button pressed
        }
        
        alertController.addAction(updateAction)
        alertController.addAction(pushNotificationsAction)
        alertController.addAction(logoutAction)
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
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }
    
    func presentUpdateProfileVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let updateProfileVC: UpdateProfileViewController = storyboard.instantiateViewController(withIdentifier: "updateProfile") as! UpdateProfileViewController
        
        // Hide tab bar in updateProfileVC
        updateProfileVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateProfileVC, animated: true)
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
        if !AYNModel.sharedInstance.wasReset {
            configureViewWithUserDefaults()
        } else {
            configureViewWithFirebase()
        }
        configureActionButtons()
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
    
    func configureViewWithUserDefaults() {
        print("Configuring view with UserDefaults")
        if let currentUserId = FIRAuth.auth()?.currentUser?.uid {
            if let savedUserDict = UserDefaultsManager.loadCurrentUser(_userId: currentUserId) as NSDictionary? {
                
                guard let userName = savedUserDict.object(forKey: "name") as? String,
                    let familyId = savedUserDict.object(forKey: "familyId") as? String,
                    let patient = savedUserDict.object(forKey: "patient") as? String else {
                        print("Incomplete profile -- deleting user")
                        // Delete here
                        FirebaseManager.deleteCurrentUser({ (error) in
                            if error != nil {
                                print("Error:", error!)
                            } else {
                                try! FIRAuth.auth()?.signOut()
                            }
                        })
                        return
                }
                
                self.userView.userNameLabel.text = userName
                self.userView.familyGroupLabel.text = familyId
                
                if let admin = savedUserDict.object(forKey: "admin") as? String {
                    if admin == "true" {
                        self.userView.specialUser("admin")
                    }
                }
                
                if let photoUrl = savedUserDict.object(forKey: "photoUrl") as? String {
                    self.configureDashboardView(photoUrl)
                }
                
                if patient == "true" {
                    self.userView.specialUser("patient")
                } else {
                    self.userView.specialUser("none")
                }
            }
        }
    }
    
    func configureViewWithFirebase() {
        print("Configuring view with Firebase -- NEW")
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error != nil {
                // Error getting user
                if error?.code == FIRStorageErrorCode.objectNotFound.rawValue {
                    print("Error getting user:", FIRStorageErrorCode.objectNotFound)
                }
            } else {
                if let userDict = userDict {
                    // Necessary values of completed profile
                    guard let userName = userDict.object(forKey: "name") as? String,
                        let familyId = userDict.object(forKey: "familyId") as? String,
                        let patient = userDict.object(forKey: "patient") as? String else {
                            print("Incomplete profile -- deleting user")
                            // Delete here
                            FirebaseManager.deleteCurrentUser({ (error) in
                                if error == nil {
                                    try! FIRAuth.auth()?.signOut()
                                }
                            })
                            return
                    }
                    
                    DispatchQueue.main.async(execute: {
                        self.userView.userNameLabel.text = userName
                        self.userView.familyGroupLabel.text = familyId
                        if patient == "true" {
                            self.userView.specialUser("patient")
                        } else {
                            self.userView.specialUser("none")
                        }
                        if let admin = userDict.object(forKey: "admin") as? String {
                            if admin == "true" {
                                self.userView.specialUser("admin")
                            }
                        }
                    })
                    
                    if let photoUrl = userDict.object(forKey: "photoUrl") as? String {
                        self.configureDashboardView(photoUrl)
                    }
                }
            }
        }
    }
    
    func configureActionButtons() {
        dashboardActionButtons.leftButton.backgroundColor = crayolaYellow
        dashboardActionButtons.leftButton.setImage(UIImage(named: "notepadIcon"), for: .normal)
        dashboardActionButtons.leftButton.tintColor = UIColor.white
        
        dashboardActionButtons.rightButton.setImage(UIImage(named: "emergencyIcon"), for: .normal)
        dashboardActionButtons.rightButton.tintColor = UIColor.white
        
        reminderActionButtonView.singleButton("left")
        reminderActionButtonView.leftButton.setTitle("Add Reminder", for: .normal)
        reminderActionButtonView.leftButton.backgroundColor = caribbeanGreen
        reminderActionButtonView.leftButton.setImage(UIImage(named: "addButton"), for: .normal)
        reminderActionButtonView.leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -25, 0, 0)
        reminderActionButtonView.leftButton.tintColor = UIColor.white
    }
    
    func notepadButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "notepad", sender: self)
    }
    
    func emergencyButtonPressed(_ sender: UIButton) {
        print("Emergency button pressed")
        let messageVC = MFMessageComposeViewController()
        messageVC.body = "EMERGENCY: I need help now!"
        messageVC.recipients = AYNModel.sharedInstance.familyMemberNumbers
        messageVC.messageComposeDelegate = self
        present(messageVC, animated: true, completion: nil)
    }
    
    func reminderButtonPressed(_ sender: UIButton) {
        print("Create new reminder")
//        self.tabBarController?.selectedIndex = 2
//        createReminder()
//        let delegate: ReminderDelegate = self
//        delegate.createReminder()
    }
    
    func checkUserSignedIn() {
        // Check for current user
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if user != nil {
                // Try to get userDict from Firebase
                FirebaseManager.getCurrentUser({ (userDict, error) in
                    if error != nil {
                        // userDict not retrieved -- check why
                        print("Error getting userDict:", error!)
                        // if userDict does not exist -- delete account & force sign up
                        // otherwise logout user
                        try! FIRAuth.auth()!.signOut()
                    } else {
                        // Make sure we don't check during onboarding
                        if !AYNModel.sharedInstance.onboarding {
                            print("User is not onboarding")
                            // userDict retrieved -- check if completed signup
                            if let userDict = userDict {
                                if let completedSignup = userDict.object(forKey: "completedSignup") as? String {
                                    if completedSignup == "true" {
                                        print("User has completed signup")
                                        self.saveCurrentUserToModel()
                                        self.configureViewWithFirebase()
                                    } else {
                                        print("User has not completed signup")
                                        // Delete account and force sign up
                                        FirebaseManager.deleteCurrentUser({ (error) in
                                            if error != nil {
                                                // Error deleting user -- sign out
                                                try! FIRAuth.auth()!.signOut()
                                            }
                                        })
                                    }
                                } else {
                                    // Key doesn't exist -- delete account & force sign up
                                    FirebaseManager.deleteCurrentUser({ (error) in
                                        if error != nil {
                                            // Error deleting user -- sign out
                                            try! FIRAuth.auth()!.signOut()
                                        }
                                    })
                                }
                            }
                        } else {
                            print("User is onboarding -- don't delete account")
                        }
                    }
                })
            } else {
                // Present onboarding VC
                print("No user is signed in -- moving to onboarding flow")
                self.presentOnboardingVC()
            }
        })
    }
    
    func deleteAccount() {
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
    
    func saveCurrentUserToModel() {
        FirebaseManager.getCurrentUser({ (userDict, error) in
            if let userDict = userDict {
                print("Saved current user to model")
                AYNModel.sharedInstance.currentUser = userDict
                self.checkNotepadForChanges()
                self.saveFamilyMemberContacts()
            }
        })
    }
    
    func checkNotepadForChanges() {
        // Retrieve last saved version from UserDefaults
        FirebaseManager.getFamilyNote { (error, note) in
            if let note = note {
                if let familyNote = UserDefaultsManager.loadCurrentNote() {
                    if note == familyNote {
                        // No changes
                        print("No changes to notepad have been made since last save")
                    } else {
                        // Changes
                        print("Changes to notepad have been made since last save")
                    }
                }
            }
        }
    }
    
    func saveFamilyMemberContacts() {
        FirebaseManager.getFamilyMembers({ (contacts, error) in
            if let contacts = contacts {
                for contact in contacts {
                    AYNModel.sharedInstance.familyMemberNumbers.append(contact.phoneNumber)
                }
                print("Saved contacts to AYNModel for emergency")
            }
        })
    }
}

extension DashboardViewController: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result.rawValue {
        case MessageComposeResult.cancelled.rawValue:
            print("Message cancelled")
        case MessageComposeResult.failed.rawValue:
            print("Message failed")
        case MessageComposeResult.sent.rawValue:
            print("Message sent")
        default:
            break
        }
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Navigation
extension DashboardViewController {
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "contactDetail" {
//            let tabBarController: UITa
//            
//            let detailNavController: UINavigationController = segue.destination as! UINavigationController
//            if let reminderVC: RemindersViewController = detailNavController.childViewControllers[0] as? RemindersViewController {
//                detailVC.contact = contact
//                detailVC.profileImage = cell.contactView.contactImageView.image
//            }
//        }
//    }
}
