//
//  UpdateProfileViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/29/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit

class UpdateProfileViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI Elements
    
    @IBOutlet var selectionView: avatarSelectionView!
    @IBOutlet var nameVTFView: validateTextFieldView!
    @IBOutlet var phoneNumberVTFView: validateTextFieldView!
    @IBOutlet var updateButton: UIButton!
    
    var userName: String!
    var userPhoneNumber: String!
    var userAvatarId: String!
    
    // MARK: - Properties
    @IBOutlet var updateButtonBottomConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.tabBarController?.tabBar.hidden = true
        
        FirebaseManager.getCurrentUser { (userDict, error) in
            if error == nil {
                if let userDict = userDict {
                    self.userName = userDict.objectForKey("name") as! String
                    self.userPhoneNumber = userDict.objectForKey("phoneNumber") as! String
                    self.userAvatarId = userDict.objectForKey("avatarId") as! String
                    
                    self.configureView()
                }
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpdateProfileViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(UpdateProfileViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        selectionView.userImageView.image = UIImage(named: userAvatarId)
        // Ensure image index is correct for switching
        selectionView.avatarImageIndex = selectionView.avatarIndex(userAvatarId)
        
        self.nameVTFView.nameMode()
        self.phoneNumberVTFView.phoneNumberMode()
        
        nameVTFView.textField.placeholder = userName
        phoneNumberVTFView.textField.placeholder = userPhoneNumber
        
        self.nameVTFView.textField.delegate = self
        self.phoneNumberVTFView.textField.delegate = self
        
        self.nameVTFView.textField.addTarget(self, action: #selector(UpdateProfileViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.phoneNumberVTFView.textField.addTarget(self, action: #selector(UpdateProfileViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        self.selectionView.previousButton.addTarget(self, action: #selector(UpdateProfileViewController.avatarDidChange(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        self.selectionView.nextButton.addTarget(self, action: #selector(UpdateProfileViewController.avatarDidChange(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        updatesToSave()
    }
    
    @IBAction func updateProfile(sender: UIButton) {
        if updatesToSave() {
            // Update profile and return to previous VC
            print("Update to save")
            var updates = ["name": nameVTFView.textField.text!, "phoneNumber": phoneNumberVTFView.textField.text!, "avatarId": selectionView.avatarId()]
            
            // Remove if no updates
            if !nameUpdate() {
                updates.removeValueForKey("name")
            }
            if !phoneNumberUpdate() {
                updates.removeValueForKey("phoneNumber")
            }
            
            if !avatarUpdate() {
                updates.removeValueForKey("avatarId")
            }
            
            FirebaseManager.updateUser(updates, completionHandler: { (error) in
                if error == nil {
                    // Return to previous VC
                    print("Profile updated -- returning to VC")
                    self.navigationController?.popToRootViewControllerAnimated(true)
                }
            })
            
        }
        else {
            print("No updates to save")
        }
    }
    
    // MARK: - Updates
    func updatesToSave() -> Bool {
        if nameUpdate() || phoneNumberUpdate() || avatarUpdate() {
            enableUpdateButton(true)
            return true
        }
        enableUpdateButton(false)
        return false
    }
    
    // Check for change in name
    func nameUpdate() -> Bool {
        if nameVTFView.textField.text != userName && validateName() {
            return true
        }
        return false
    }
    
    // Check for change in phone number
    func phoneNumberUpdate() -> Bool {
        if phoneNumberVTFView.textField.text != userPhoneNumber && validatePhoneNumber() {
            return true
        }
        return false
    }
    
    // Check for change in avatarId
    func avatarUpdate() -> Bool {
        if selectionView.avatarId() != userAvatarId {
            return true
        }
        return false
    }
    
    // MARK: - Validation
    func validateName() -> Bool {
        let valid = !nameVTFView.textField.text!.isEmpty
        if valid {
            nameVTFView.isValid(true)
            return true
        }
        else {
            nameVTFView.isValid(false)
            return false
        }
    }
    
    func validatePhoneNumber() -> Bool {
        let PHONE_REGEX = "^\\d{3}\\d{3}\\d{4}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", PHONE_REGEX)
        let valid = phoneTest.evaluateWithObject(phoneNumberVTFView.textField.text!)
        if valid {
            phoneNumberVTFView.isValid(true)
            return true
        }
        else {
            phoneNumberVTFView.isValid(false)
            return false
        }
    }
    
    func enableUpdateButton(enable: Bool) {
        if enable {
           updateButton.alpha = 1
            updateButton.enabled = true
        }
        else {
            updateButton.alpha = 0.5
            updateButton.enabled = false
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldDidChange(textField: UITextField) {
        let tag = textField.superview!.superview!.tag
        
        switch tag {
        // Name textField
        case 0:
            validateName()
        // Phone number textField
        case 1:
            validatePhoneNumber()
        default:
            break
        }
        
        updatesToSave()
    }
    
    // MARK: - SelectionView
    func avatarDidChange(button: UIButton) {
        updatesToSave()
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let changeInHeight = (CGRectGetHeight(keyboardFrame)) //* (show ? 1 : -1)
        
        if show {
            UIView.animateWithDuration(animationDuration) {
                self.updateButtonBottomConstraint.constant = changeInHeight
            }
        }
        else {
            UIView.animateWithDuration(animationDuration) {
                self.updateButtonBottomConstraint.constant = 0
            }
        }
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(true, notification: sender)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(false, notification: sender)
    }

}
