//
//  CreateUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

class CreateUserViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI Elements
    @IBOutlet var emailVTFView: validateTextFieldView!
    @IBOutlet var passwordVTFView: validateTextFieldView!
    @IBOutlet var confirmPasswordVTFView: validateTextFieldView!
    @IBOutlet var nextButton: UIButton!
    
    var errorPopoverView: popoverView!
    var shadowView: UIView!
    
    // MARK: - Properties
    var userSignedUp = false
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.presentTransparentNavBar()
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateUserViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(CreateUserViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
        
        self.emailVTFView.textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func configureView() {
        self.emailVTFView.emailMode()
        self.passwordVTFView.passwordMode(false)
        self.confirmPasswordVTFView.passwordMode(true)
        
        self.emailVTFView.textField.delegate = self
        self.passwordVTFView.textField.delegate = self
        self.confirmPasswordVTFView.textField.delegate = self
        
        self.emailVTFView.textField.addTarget(self, action: #selector(CreateUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.passwordVTFView.textField.addTarget(self, action: #selector(CreateUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.confirmPasswordVTFView.textField.addTarget(self, action: #selector(CreateUserViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)

        nextButtonEnabled()
    }
    
    @IBAction func presentNextView(sender: UIButton) {
        signUpUser()
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if validateEmail() {
                passwordVTFView.textField.becomeFirstResponder()
            }
        case 1:
            if validatePassword() {
                confirmPasswordVTFView.textField.becomeFirstResponder()
            }
        case 2:
            if validateConfirmPassword(){
                signUpUser()
            }
        default:
            break
        }
        return true
    }
    
    func textFieldDidChange(textField: UITextField) {
        let tag = textField.superview!.superview!.tag
        
        switch tag {
        // Email textField
        case 0:
            validateEmail()
        // Password textField
        case 1:
            validatePassword()
        // Confirm password textField
        case 2:
            validateConfirmPassword()
        default:
            break
        }
        
        nextButtonEnabled()
    }
    
    func nextButtonEnabled() {
        if validFields() {
            nextButton.enabled = true
            nextButton.alpha = 1
        }
        else {
            nextButton.enabled = false
            nextButton.alpha = 0.5
        }
    }
    
    func nextButtonEnabled(enabled: Bool) {
        if enabled {
            nextButton.enabled = true
            nextButton.alpha = 1
        }
        else {
            nextButton.enabled = false
            nextButton.alpha = 0.5
        }
    }
    
    // MARK: - Firebase
    func signUpUser() {
        if validFields() {
            
            // Disable interface to avoid extra interaction
            interfaceEnabled(false)
            
            // Show progress view
            HUD.show(.Progress)
            
            FirebaseManager.createNewUserWithEmail(emailVTFView.textField.text!, password: passwordVTFView.textField.text!, completionHandler: { (user, error) in
                if error != nil {
                    // Hide progress view
                    HUD.hide()
                    
                    // Sign up failed -- show popoverView with reason
                    self.showPopoverView(error!)
                    
                    self.interfaceEnabled(true)
                }
                else {
                    // Successfully signed up
                    if user != nil {
                        
                        let updates = ["email": self.emailVTFView.textField.text!, "completedSignup": "updateUser"]
                        
                        FirebaseManager.updateUser(updates, completionHandler: { (error) in
                            if error == nil {
                                // success -- Show progress view success
                                HUD.flash(.Success, delay: 0.2, completion: { (success) in
                                    self.view.endEditing(true)
                                    self.userSignedUp = true
                                    AYNModel.sharedInstance.wasReset = true
                                    
                                    self.performSegueWithIdentifier("updateUser", sender: self)
                                })
                            }
                        })
                    }
                }
            })
        }
    }
    
    // MARK: - Validation
    func validFields() -> Bool {
        return validateEmail() && validatePassword() && validateConfirmPassword()
    }
    
    func validateEmail() -> Bool {
        // Check empty
        if emailVTFView.textField.text!.isEmpty {
//            print("Email field empty")
            emailVTFView.isValid(false)
            return false
        }
        else {
            // Check valid
            let userEmailAddress = emailVTFView.textField.text
            let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluateWithObject(userEmailAddress)
            
            // For debugging
            if valid {
                emailVTFView.isValid(true)
                return true
            }
            else {
//                print("Invalid email")
                emailVTFView.isValid(false)
                return false
            }
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
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "updateUser" {
            return userSignedUp
        }
        return false
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
        
        UIView.performWithoutAnimation({
            self.emailVTFView.layoutIfNeeded()
            self.passwordVTFView.layoutIfNeeded()
            self.confirmPasswordVTFView.layoutIfNeeded()
        })
        
        if show {
            self.nextButtonBottomConstraint.constant = changeInHeight
        }
        else {
            self.nextButtonBottomConstraint.constant = 0
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
        errorPopoverView.confirmButton.addTarget(self, action: #selector(CreateUserViewController.hidePopoverView(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        // Configure shadow view
        shadowView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        shadowView.backgroundColor = UIColor.blackColor()
        
        self.view.addSubview(shadowView)
        self.view.addSubview(errorPopoverView)
        
        errorPopoverView.hidden = false
        errorPopoverView.alpha = 0
        
        shadowView.hidden = false
        shadowView.alpha = 0
        
        UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.errorPopoverView.alpha = 1
            self.shadowView.alpha = 0.2
            }, completion: { (completed) in
        })
    }
    
    func hidePopoverView(sender: UIButton) {
        UIView.animateWithDuration(0.25, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.errorPopoverView.alpha = 0
            self.shadowView.alpha = 0
            }, completion: { (completed) in
                self.errorPopoverView.hidden = true
                self.shadowView.hidden = true
                
                self.errorPopoverView.removeFromSuperview()
                self.shadowView.removeFromSuperview()
                
                // Show keyboard again
                self.confirmPasswordVTFView.textField.becomeFirstResponder()
        })
    }

    // MARK: - Interface Enable / Disable
    func interfaceEnabled(enabled: Bool) {
        nextButtonEnabled(enabled)
        self.navigationController?.navigationItem.backBarButtonItem?.enabled = enabled
        emailVTFView.textField.userInteractionEnabled = enabled
        passwordVTFView.textField.userInteractionEnabled = enabled
        confirmPasswordVTFView.userInteractionEnabled = enabled
    }
}
