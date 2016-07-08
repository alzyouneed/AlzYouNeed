//
//  FamilySignupViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class FamilySignupViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Properties
    var newFamily = true
    @IBOutlet var familyButtonBottomConstraint: NSLayoutConstraint!
    
    // MARK: - UI Elements
    @IBOutlet var familyIdVTFView: validateTextFieldView!
    @IBOutlet var passwordVTFView: validateTextFieldView!
    @IBOutlet var confirmPasswordVTFView: validateTextFieldView!
    @IBOutlet var createJoinFamilyButton: UIButton!
    
    @IBOutlet var progressView: UIProgressView!
    
    // MARK: - Popover View Properties
    var errorPopoverView: popoverView!
    var shadowView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FamilySignupViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(FamilySignupViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
        familyIdVTFView.textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
        UIView.animateWithDuration(0.5) {
            self.progressView.setProgress(0.825, animated: true)
        }

        // Animate status bar hidden
        UIView.animateWithDuration(0.2) { 
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    // MARK: - Firebase
    func createNewFamily(familyId: String, password: String) {
        FirebaseManager.createNewFamilyGroup(familyId, password: password) { (error, newDatabaseRef) in
            if error != nil {
                // Error creating new family
                self.showPopoverView(error!)
            }
            else {
                // Successfully created new family
                self.view.endEditing(true)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    func joinFamily(familyId: String, password: String) {
        FirebaseManager.joinFamilyGroup(familyId, password: password) { (error, newDatabaseRef) in
            if error != nil {
                // Error joining family
                self.showPopoverView(error!)
            }
            else {
                // Successfully joined family
                self.view.endEditing(true)
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
    }
    
    @IBAction func createOrJoinFamily(sender: UIButton) {
        // Check if fields valid
        if validFields() {
            // Create family
            if newFamily {
                createNewFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
            }
                // Join family
            else {
                joinFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
            }
        }
    }
    
    func configureView() {
        configureTextFieldViews()
        configureButton()
        createJoinFamilyButtonEnabled()
    }
    
    func configureTextFieldViews() {
        self.familyIdVTFView.familyIdMode()
        self.passwordVTFView.passwordMode(false)
        self.confirmPasswordVTFView.passwordMode(true)
        
        self.familyIdVTFView.textField.delegate = self
        self.passwordVTFView.textField.delegate = self
        self.confirmPasswordVTFView.textField.delegate = self
        
        self.familyIdVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.passwordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.confirmPasswordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

    }
    
    func configureButton() {
        if newFamily {
            confirmPasswordVTFView.hidden = false
            // set button title
            createJoinFamilyButton.setTitle("Create Family", forState: UIControlState.Normal)
            passwordVTFView.textField.returnKeyType = UIReturnKeyType.Next
        }
        else {
            confirmPasswordVTFView.hidden = true
            // set button title
            createJoinFamilyButton.setTitle("Join Family", forState: UIControlState.Normal)
            passwordVTFView.textField.returnKeyType = UIReturnKeyType.Done
        }
    }
    
    func createJoinFamilyButtonEnabled() {
        if validFields() {
            createJoinFamilyButton.enabled = true
            createJoinFamilyButton.alpha = 1
        }
        else {
            createJoinFamilyButton.enabled = false
            createJoinFamilyButton.alpha = 0.5
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if validateFamilyId() {
                passwordVTFView.textField.becomeFirstResponder()
            }
        case 1:
            if validatePassword() {
                if newFamily {
                    confirmPasswordVTFView.textField.becomeFirstResponder()
                }
                else {
                    // Join family
//                    print("Join family")
                    joinFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
                }
            }
        case 2:
            if validateConfirmPassword() {
                self.view.endEditing(true)
                // create family
//                print("Create family")
                createNewFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
            }
        default:
            break
        }
        return true
    }
    
    func textFieldDidChange(textField: UITextField) {
        if newFamily {
            let tag = textField.superview!.superview!.tag
            switch tag {
            // FamilyId textField
            case 0:
                validateFamilyId()
            // Password textField
            case 1:
                validatePassword()
            // Confirm password textField
            case 2:
                validateConfirmPassword()
            default:
                break
            }
        }
        createJoinFamilyButtonEnabled()
    }
    
    // MARK: - Validation
    func validFields() -> Bool {
        if newFamily {
            return validateFamilyId() && validatePassword() && validateConfirmPassword()
        }
        else {
            return !familyIdVTFView.textField.text!.isEmpty && !passwordVTFView.textField.text!.isEmpty
        }
    }
    
    func validateFamilyId() -> Bool {
        // Check empty
        if familyIdVTFView.textField.text!.isEmpty {
//            print("FamilyId field empty")
            familyIdVTFView.isValid(false)
            return false
        }
        else {
            familyIdVTFView.isValid(true)
            return true
        }
    }
    
    func validatePassword() -> Bool {
        if passwordVTFView.textField.text!.isEmpty {
//            print("Password field empty")
            passwordVTFView.isValid(false)
            return false
        }
        
        if passwordVTFView.textField.text?.characters.count < 6 {
//            print("Password not long enough")
            passwordVTFView.isValid(false)
            return false
        }
        
        passwordVTFView.isValid(true)
        return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPasswordVTFView.textField.text!.isEmpty {
//            print("Confirm password field empty")
            confirmPasswordVTFView.isValid(false)
            return false
        }
        
        let passwordText = passwordVTFView.textField.text
        let confirmPasswordText = confirmPasswordVTFView.textField.text
        let passwordsMatch = passwordText == confirmPasswordText
        
        if passwordsMatch {
            confirmPasswordVTFView.isValid(true)
            return true
        }
        else {
            //            print("Passwords do not match")
            confirmPasswordVTFView.isValid(false)
            return false
        }
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSTimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.unsignedLongValue ?? UIViewAnimationOptions.CurveEaseInOut.rawValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (CGRectGetHeight(keyboardFrame)) //* (show ? 1 : -1)
        
        
        if show {
            self.familyButtonBottomConstraint.constant = changeInHeight
        }
        else {
            self.familyButtonBottomConstraint.constant = 0
        }
        UIView.animateWithDuration(animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(true, notification: sender)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(false, notification: sender)
    }
    
    // MARK: - Popover View
    func showPopoverView(error: NSError) {
        // Hide keyboard
        self.view.endEditing(true)
        
        // Configure view size
        errorPopoverView = popoverView(frame: CGRect(x: self.view.frame.width/2 - 100, y: self.view.frame.height/2 - 200, width: 200, height: 200))
        // Add popover message
        errorPopoverView.configureWithError(error)
        // Add target to hide view
        errorPopoverView.confirmButton.addTarget(self, action: #selector(FamilySignupViewController.hidePopoverView(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        // Configure shadow view
        shadowView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        shadowView.backgroundColor = UIColor.blackColor()
        
        self.view.addSubview(shadowView)
        self.view.addSubview(errorPopoverView)
        
        errorPopoverView.hidden = false
        errorPopoverView.alpha = 0
        
        shadowView.hidden = false
        shadowView.alpha = 0
        
        dispatch_async(dispatch_get_main_queue()) { 
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.errorPopoverView.alpha = 1
                self.shadowView.alpha = 0.2
                }, completion: { (completed) in
            })
        }
    }
    
    func hidePopoverView(sender: UIButton) {
        dispatch_async(dispatch_get_main_queue()) { 
            UIView.animateWithDuration(0.25, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                self.errorPopoverView.alpha = 0
                self.shadowView.alpha = 0
                }, completion: { (completed) in
                    self.errorPopoverView.hidden = true
                    self.shadowView.hidden = true
                    
                    self.errorPopoverView.removeFromSuperview()
                    self.shadowView.removeFromSuperview()
                    
                    // Show keyboard again
                    if self.newFamily {
                        self.confirmPasswordVTFView.textField.becomeFirstResponder()
                    }
                    else {
                        self.passwordVTFView.textField.becomeFirstResponder()
                    }
            })
        }
    }
    
}
