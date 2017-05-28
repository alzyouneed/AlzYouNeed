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
    var viewSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.presentTransparentNavBar()
        UIApplication.shared.statusBarStyle = .lightContent
        
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 18)!]
        
        self.tabBarController?.tabBar.layer.borderWidth = 0.5
        self.tabBarController?.tabBar.layer.borderColor = UIColor.lightGray.cgColor
        
        setupNotepad()
        setupEmergencyButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupAuthListener()
 
        setupUserNameLabel()
        
        checkUserImageChanged()
        
        self.navigationController?.navigationBar.tintColor = UIColor.white
        UIApplication.shared.statusBarStyle = .lightContent
        
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
        
        let updateAction = UIAlertAction(title: "Profile", style: .default) { (action) in
            self.presentUpdateProfileVC()
        }
        let logoutAction = UIAlertAction(title: "Logout", style: .default) { (action) in
            // Log analytics event
//            FIRAnalytics.logEvent(withName: "logout", parameters: nil)
            Answers.logCustomEvent(withName: "Logout",
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
        alertController.addAction(logoutAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func saveNotepad(_ sender: UIBarButtonItem) {
        saveNote(_dismissAfter: true)
    }
    
    // MARK: - Configuration
    func setupView() {
        setupUserView()
//        setupNotepad()
//        setupEmergencyButton()
    }
    
    func setupUserView() {
        if let user = FIRAuth.auth()?.currentUser {
            // Check if AYNModel has image
            if let image = AYNModel.sharedInstance.userImage {
                DispatchQueue.main.async(execute: {
                    self.userView.setImage(image)
                })
            } else if let imageURL = user.photoURL, let data = try? Data(contentsOf: imageURL) {
                if let image = UIImage(data: data) as UIImage? {
                    AYNModel.sharedInstance.userImage = image
                    
                    DispatchQueue.main.async(execute: {
                        self.userView.setImage(image)
                    })
                }
            } else {
                let defaultImage = UIImage.fontAwesomeIcon(name: .user, textColor: UIColor(hex: "7189FF"), size: CGSize(width: 80, height: 80))
                AYNModel.sharedInstance.userImage = defaultImage
                DispatchQueue.main.async(execute: {
                    self.userView.setImage(defaultImage)
                })
            }
            
            self.userView.userNameLabel.text = user.displayName?.components(separatedBy: " ").first
            
            if let groupId = AYNModel.sharedInstance.groupId {
                DispatchQueue.main.async {
                    self.userView.familyGroupLabel.text = groupId
                }
            }
        }
    }
    
    func checkUserImageChanged() {
        if FIRAuth.auth()?.currentUser != nil {
            // Check if AYNModel has image
            if let image = AYNModel.sharedInstance.userImage {
                DispatchQueue.main.async(execute: {
                    self.userView.setImage(image)
                })
            }
        }
    }
    
    func setupUserNameLabel() {
        if let user = FIRAuth.auth()?.currentUser {
            self.userView.userNameLabel.text = user.displayName?.components(separatedBy: " ").first
        }
    }
    
    func setupNotepad() {
        saveButton.isEnabled = false
        saveButton.tintColor = UIColor.clear
        
        notepadView.notesTextView.isUserInteractionEnabled = false
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DashboardViewController.tappedNotepad))
        notepadView.addGestureRecognizer(tap)
        let notesTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DashboardViewController.tappedNotes))
        notepadView.notesTextView.addGestureRecognizer(notesTap)
        // Round the bounds
        notepadView.layer.cornerRadius = 10
        notepadView.layer.masksToBounds = true
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
                    AYNModel.sharedInstance.userImage = image
                    // Reset variable only after configuration is complete
                    AYNModel.sharedInstance.wasReset = false
                }
            })
        } else if let url = URL(string: imageUrl), let data = try? Data(contentsOf: url) {
            if let image = UIImage(data: data) as UIImage? {
                
                DispatchQueue.main.async(execute: {
                    self.userView.setImage(image)
                })
                AYNModel.sharedInstance.userImage = image
                // Reset variable only after configuration is complete
                AYNModel.sharedInstance.wasReset = false
            }
        }
    }
    
    func setupAuthListener() {
        authListener = FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if user != nil {
                if !self.viewSetup {
                    
                    self.viewSetup = true
                    
                    // Load from defaults first to reduce visible delay
                    AYNModel.sharedInstance.loadFromDefaults(completionHandler: { (success) in
                        if success {
                            self.setupView()
                        }
                    })
                    
                    // Load from Firebase to get newest user data
                    AYNModel.sharedInstance.loadFromFirebase(completionHandler: { (success) in
                        if success {
                            self.setupView()
                            self.saveFamilyMemberContacts()
                            self.loadNote()
                            self.registerNotifications()
                        }
                    })
                }
            } else {
                print("DashboardVC: No user signed in -- showing onboarding")
                self.presentOnboardingVC()
            }
        })
    }
    
    // MARK: - Present different VC's
    func presentOnboardingVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let onboardingVC: UINavigationController = storyboard.instantiateViewController(withIdentifier: "loginNav") as! UINavigationController
        self.present(onboardingVC, animated: true, completion: nil)
    }
    
    func presentUpdateProfileVC() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let updateProfileTVC: UpdateProfileTVC = storyboard.instantiateViewController(withIdentifier: "updateProfile") as! UpdateProfileTVC
        
//        let updateProfileVC: UpdateProfileViewController = storyboard.instantiateViewController(withIdentifier: "updateProfile") as! UpdateProfileViewController
        
        // Hide tab bar in updateProfileVC
        updateProfileTVC.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(updateProfileTVC, animated: true)
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
    
    func notepadButtonPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "notepad", sender: self)
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
                // Save contacts 
                AYNModel.sharedInstance.contactsArr = contacts
                
                for contact in contacts {
                    if let phoneNumber = contact.phoneNumber {
                        AYNModel.sharedInstance.familyMemberNumbers.append(phoneNumber)
                    }
                }
                if !AYNModel.sharedInstance.familyMemberNumbers.isEmpty {
                    print("Saved contacts to AYNModel for emergency")
                    self.emergencyButton.isHidden = false
                    self.emergencyButton.isEnabled = true
                }
            }
        })
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
                    UIApplication.shared.registerForRemoteNotifications()
                } else {
                    print("Push notification auth denied")
                }
            }
        }
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
    func setupEmergencyButton() {
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
                    UserDefaultsManager.saveCurrentUserNotepad(note: note)
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
