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
import UserNotifications
import Crashlytics

class DashboardViewController: UIViewController {
    
    @IBOutlet var userView: UserDashboardView!
    @IBOutlet var dateView: DateDashboardView!
    @IBOutlet var dashboardActionButtons: actionButtonsDashboardView!
    @IBOutlet var reminderActionButtonView: actionButtonsDashboardView!

    @IBOutlet var settingsButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    @IBOutlet var emergencyButton: UIButton!
    
    @IBOutlet var bottomSectionView: UIView!
    var notepadActive = false
    var originalNote = ""
    @IBOutlet var notepadView: notepadView!
    @IBOutlet var notepadTopConstraint: NSLayoutConstraint!
    @IBOutlet var notepadVeryTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var notepadTopUserViewConstraint: NSLayoutConstraint!
    @IBOutlet var notepadBottomConstraint: NSLayoutConstraint!
    
    var authListener: FIRAuthStateDidChangeListenerHandle?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: Fix this
//        checkUserSignedIn()

        dashboardActionButtons.leftButton.addTarget(self, action: #selector(DashboardViewController.notepadButtonPressed(_:)), for: [UIControlEvents.touchUpInside])
        
//        reminderActionButtonView.leftButton.addTarget(self, action: #selector(DashboardViewController.reminderButtonPressed(_:)), for: [UIControlEvents.touchUpInside])
        
        configureView()
        configureEmergencyButton()
        configureNotepadView()
        self.navigationController?.presentTransparentNavBar()
        
        self.tabBarController?.tabBar.layer.borderWidth = 0.5
        self.tabBarController?.tabBar.layer.borderColor = UIColor.lightGray.cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        authListener = FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if let user = user {
                print("DashboardVC: User signed in: ", user)
            } else {
                print("DashboardVC: No user signed in -- showing onboarding")
                self.presentOnboardingVC()
            }
        })
        
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
        
        // Configure for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(DashboardViewController.keyboardWillShow(sender:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DashboardViewController.keyboardWillHide(sender:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let now = Date()
        dateView.configureView(now)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if let authListener = authListener {
            FIRAuth.auth()?.removeStateDidChangeListener(authListener)
        }
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
            // Log analytics event
//            FIRAnalytics.logEvent(withName: "logout", parameters: nil)
            Answers.logCustomEvent(withName: "logout",
                                           customAttributes: [:])
            
            // Clean up current session
            AYNModel.sharedInstance.resetModel()
            self.updateTabBadge()
            self.resetView()
            
            // Remove any pending notifications
            if UIApplication.shared.isRegisteredForRemoteNotifications {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                print("Removed pending notifications")
            }
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
    
    @IBAction func saveNotepad(_ sender: UIBarButtonItem) {
        print("saved notepad")
        saveNote(_dismissAfter: true)
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
                        print("Error deleting user: \(String(describing: error))")
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
                    print("Error logging in: \(String(describing: error))")
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
        
        // Configure save button
        saveButton.isEnabled = false
        saveButton.tintColor = UIColor.clear
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
                
                // Save device token here: TODO
                
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
        dashboardActionButtons.singleButton("left")
        dashboardActionButtons.leftButton.backgroundColor = crayolaYellow
        dashboardActionButtons.leftButton.setImage(UIImage(named: "notepadIcon"), for: .normal)
        dashboardActionButtons.leftButton.tintColor = UIColor.white
        
        reminderActionButtonView.singleButton("left")
        reminderActionButtonView.leftButton.setTitle("Add Reminder", for: .normal)
        reminderActionButtonView.leftButton.backgroundColor = caribbeanGreen
        reminderActionButtonView.leftButton.setImage(UIImage(named: "addButton"), for: .normal)
        reminderActionButtonView.leftButton.imageEdgeInsets = UIEdgeInsetsMake(0, -25, 0, 0)
        reminderActionButtonView.leftButton.tintColor = UIColor.white
    }
    
    func configureNotepadView() {
        notepadView.notesTextView.isUserInteractionEnabled = false
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DashboardViewController.tappedNotepad))
        notepadView.addGestureRecognizer(tap)
        
        let notesTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DashboardViewController.tappedNotes))
        notepadView.notesTextView.addGestureRecognizer(notesTap)
        
        // Round the bounds
        notepadView.layer.cornerRadius = 10
        notepadView.layer.masksToBounds = true
//        notepadView.clipsToBounds = true
//        notepadView.layer.shadowColor = UIColor.black.cgColor
//        notepadView.layer.shadowOffset = CGSize(width: 0, height: -1)
//        notepadView.layer.shadowOpacity = 0.9
//        notepadView.layer.shadowRadius = 5
    }
    
    func notepadButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "notepad", sender: self)
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
                    print("Error deleting user: \(String(describing: error))")
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
//                self.checkNotepadForChanges()
                self.saveFamilyMemberContacts()
                self.loadNote()
                self.registerNotifications()
            }
        })
    }
    
    func checkNotepadForChanges() {
        // Retrieve last saved version from UserDefaults
        FirebaseManager.getFamilyNote { (error, note) in
            if let note = note {
                if let familyNote = UserDefaultsManager.loadCurrentNote() {
                    if note["note"] == familyNote {
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
    
    func emergencyAction(sender: UIButton) {
        print("Emergency button pressed")
    }
    
    // MARK: - Push Notifications
    func registerNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            if error != nil {
                print("Error requesting push notification auth:", error!)
            } else {
                if granted {
                    print("Push notification auth granted")
                } else {
                    print("Push notification auth denied")
                }
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
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

// MARK: - Emergency button
extension DashboardViewController {
    func configureEmergencyButton() {
        print("Configuring emergency button")
        emergencyButton.backgroundColor = sunsetOrange
        emergencyButton.layer.cornerRadius = emergencyButton.frame.width/2
        emergencyButton.layer.shadowRadius = 1
        emergencyButton.layer.shadowColor = UIColor.black.cgColor
        emergencyButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        emergencyButton.layer.shadowOpacity = 0.5
        
        emergencyButton.addTarget(self, action: #selector(DashboardViewController.emergencyButtonPressed(_:)), for: [.touchUpInside, .touchDown])
    }
    
    func emergencyButtonPressed(_ sender: UIButton) {
        print("Emergency button pressed")
        let messageVC = MFMessageComposeViewController()
        messageVC.body = "EMERGENCY: I need help now!"
        messageVC.recipients = AYNModel.sharedInstance.familyMemberNumbers
        messageVC.messageComposeDelegate = self
        present(messageVC, animated: true, completion: nil)
    }

}

// MARK: - Notepad View
extension DashboardViewController {
    func tappedNotepad() {
//        print("tapped notepad")
        if !notepadActive {
            expandNotepad()
        } else {
            collapseNotepad()
        }
    }
    
    func tappedNotes() {
//        print("tapped notes view")
    }
    
    @IBAction func closeNotepad(_ sender: UIBarButtonItem) {
        if notepadView.notesTextView.text != originalNote {
            // Unsaved changes - warn user
            showChangesWarning()
        } else {
            // No changes - dismiss
            collapseNotepad()
        }
    }
    
    func expandNotepad() {
        if !notepadActive {
            notepadActive = true

            // Change active constraints
            notepadTopConstraint.isActive = false
//            notepadVeryTopConstraint.isActive = true
            notepadTopUserViewConstraint.isActive = true
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.notepadView.changesLabel.alpha = 0
                self.notepadView.superview?.layoutIfNeeded()
            }, completion: { (completed) in
                // Adjust navigation bar buttons
                self.settingsButton.title = "Cancel"
                self.settingsButton.image = nil
                self.settingsButton.action = #selector(DashboardViewController.closeNotepad(_:))
                
                self.notepadView.notesTextView.isUserInteractionEnabled = true
                
                self.saveButton.isEnabled = true
                self.saveButton.tintColor = UIColor.white
                
                self.checkTutorialStatus()
            })
        }
    }
    
    func collapseNotepad() {
        if notepadActive {
            notepadActive = false
            
            // Change active constraints
            notepadTopConstraint.isActive = true
//            notepadVeryTopConstraint.isActive = false
            notepadTopUserViewConstraint.isActive = false
            
            // Reset navigation bar buttons
            settingsButton.title = nil
            settingsButton.image = #imageLiteral(resourceName: "settingsIcon")
            settingsButton.action = #selector(DashboardViewController.showSettings(_:))
            
            self.view.endEditing(true)
            
            saveButton.isEnabled = false
            saveButton.tintColor = UIColor.clear
            
//            self.title = nil
            
            UIView.animate(withDuration: 0.2, animations: {
                self.notepadView.changesLabel.alpha = 1
//                self.view.backgroundColor = slateBlue
//                self.view.layoutIfNeeded()
                self.notepadView.superview?.layoutIfNeeded()
            })
            notepadView.notesTextView.isUserInteractionEnabled = false
        }
    }
    
    func loadNote() {
        FirebaseManager.getFamilyNote { (error, familyNote) in
            if let familyNote = familyNote {
                if let note = familyNote["note"] as String? {
                    self.originalNote = note
                    DispatchQueue.main.async {
                        self.notepadView.notesTextView.text = note
                    }
                    
                    // Saved to UserDefaults to notify user to changes
                    UserDefaultsManager.saveCurrentUserNotepad(_note: note)
                }

                if let lastChangedName = familyNote["lastChangedName"] as String? {
                    self.notepadView.changesLabel.text = "Last change: \(lastChangedName)"
                }
                
                if let lastChangedUser = familyNote["lastChangedUser"] as String? {
                    if lastChangedUser == FIRAuth.auth()?.currentUser?.uid {
                        self.notepadView.changesLabel.text = "Last change: You"
                    }
                }
            }
        }
    }
    
    func saveNote(_dismissAfter: Bool) {
        if !notepadView.notesTextView.text.isEmpty {
            FirebaseManager.saveFamilyNote(_changes: notepadView.notesTextView.text) { (error) in
                if error != nil {
                    // Didn't save note
                } else {
                    // Saved note
                    self.originalNote = self.notepadView.notesTextView.text
                    self.notepadView.changesLabel.text = "Last change: You"
                    self.collapseNotepad()
                }
            }
        }
    }
    
    // MARK: Tutorial
    func checkTutorialStatus() {
        if let notepadTutorialCompleted = UserDefaultsManager.getTutorialCompletion(tutorial: Tutorials.notepad.rawValue) as String? {
            if notepadTutorialCompleted == "false" {
                showTutorial()
            } else {
                print("Notepad tutorial completed")
            }
        }
    }
    
    func showTutorial() {
        let alertController = UIAlertController(title: "Tutorial", message: "Store anything important here!", preferredStyle: .alert)
        
        let completeAction = UIAlertAction(title: "Got it!", style: .default) { (action) in
            UserDefaultsManager.completeTutorial(tutorial: "notepad")
        }
        
        alertController.addAction(completeAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showChangesWarning() {
        let alertController = UIAlertController(title: "Unsaved Changes", message: "All changes will be lost unless you save them", preferredStyle: .actionSheet)
        
        let closeAction = UIAlertAction(title: "Close without saving", style: .destructive) { (action) in
            self.collapseNotepad()
            self.notepadView.notesTextView.text = self.originalNote
        }
        let saveAction = UIAlertAction(title: "Save changes", style: .default) { (action) in
            self.saveNote(_dismissAfter: true)
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(closeAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - Keyboard
extension DashboardViewController {
    // MARK: - Keyboard
    func adjustingKeyboardHeight(_ show: Bool, notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
        if show {
            self.notepadBottomConstraint.constant = changeInHeight - (self.tabBarController?.tabBar.frame.height)!
        } else {
            self.notepadBottomConstraint.constant = 0
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(true, notification: sender as Notification)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(false, notification: sender as Notification)
    }
}
