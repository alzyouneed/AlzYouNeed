//
//  CreateUserViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class CreateUserViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - UI Elements
    @IBOutlet var emailVTFView: validateTextFieldView!
    @IBOutlet var passwordVTFView: validateTextFieldView!
    @IBOutlet var confirmPasswordVTFView: validateTextFieldView!
    @IBOutlet var nextButton: UIButton!
    
    // MARK: - Properties
    var userSignedUp = false
    @IBOutlet var nextButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
            
            // Disable button to avoid multiple taps
            nextButtonEnabled(false)
            
            FirebaseManager.createNewUserWithEmail(emailVTFView.textField.text!, password: passwordVTFView.textField.text!, completionHandler: { (user, error) in
                if error != nil {
                    // Sign up failed
                    self.nextButtonEnabled(true)
                }
                else {
                    // Successfully signed up
                    if user != nil {
                        
                        let updates = ["email": self.emailVTFView.textField.text!, "completedSignup": "updateUser"]
                        
                        FirebaseManager.updateUser(updates, completionHandler: { (error) in
                            if error == nil {
                                // success
                                
                                self.view.endEditing(true)
                                self.userSignedUp = true
                                
                                self.performSegueWithIdentifier("updateUser", sender: self)
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
        let changeInHeight = (CGRectGetHeight(keyboardFrame)) //* (show ? 1 : -1)
        
        if show {
            UIView.animateWithDuration(animationDuration) {
                self.nextButtonBottomConstraint.constant = changeInHeight
            }
        }
        else {
            UIView.animateWithDuration(animationDuration) {
                self.nextButtonBottomConstraint.constant = 0
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
