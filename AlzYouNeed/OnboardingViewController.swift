//
//  OnboardingViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/16/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class OnboardingViewController: UIViewController, UITextFieldDelegate {
    
    var loginMode = false
    
    @IBOutlet var emailVTFView: validateTextFieldView!
    @IBOutlet var passwordVTFView: validateTextFieldView!
    
    @IBOutlet var loginButtons: loginButtonsView!
    @IBOutlet var loginButtonsBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var logoImageView: UIImageView!
    @IBOutlet var appNameLabel: UILabel!
    
    // MARK: - Popover View Properties
    var errorPopoverView: popoverView!
    var shadowView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView() {
        self.emailVTFView.emailMode()
        self.passwordVTFView.passwordMode(false)
        
        self.emailVTFView.textField.delegate = self
        self.passwordVTFView.textField.delegate = self

        loginButtons.leftButton.addTarget(self, action: #selector(OnboardingViewController.leftButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        loginButtons.rightButton.addTarget(self, action: #selector(OnboardingViewController.rightButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        // Remove observers
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        
        self.navigationController?.setNavigationBarHidden(false, animated: animated);
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OnboardingViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OnboardingViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        loginButtons.resetState()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func signUp() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let createUserVC: CreateUserViewController = storyboard.instantiateViewControllerWithIdentifier("createUserVC") as! CreateUserViewController
        self.navigationController?.pushViewController(createUserVC, animated: true)
    }
    
    func loginUser() {
        if !loginMode {
            showLoginView()
        }
        else {
            if validateLogin() {
                FIRAuth.auth()?.signInWithEmail(emailVTFView.textField.text!, password: passwordVTFView.textField.text!, completion: { (user, error) in
                    if error == nil {
                        print("Login successful")
                        self.view.endEditing(true)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    else {
                        print(error)
                        self.showPopoverView(error!)
                    }
                })
            }
        }
    }
    
    func leftButtonAction(sender: UIButton) {
        switch sender.currentTitle! {
        case "Sign up":
            signUp()
        case "Login":
            loginUser()
        default:
            break
        }
    }
    
    func rightButtonAction(sender: UIButton) {
        switch sender.currentTitle! {
        case "Login":
            loginUser()
        case "Cancel":
            hideLoginView()
            self.view.endEditing(true)
        default:
            break
        }
    }
    
    // MARK: - Validation
    func validateLogin() -> Bool {
        if emailVTFView.textField.text!.isEmpty {
            print("Missing email")
            return false
        }
        if passwordVTFView.textField.text!.isEmpty {
            print("Missing password")
            return false
        }
        return true
    }
    
    // MARK: - Login View
    func showLoginView() {
        if !loginMode {
            loginMode = true

            self.emailVTFView.hidden = false
            self.passwordVTFView.hidden = false
            
            self.logoImageView.hidden = true
            self.appNameLabel.hidden = true

            self.emailVTFView.alpha = 0
            self.passwordVTFView.alpha = 0
            
            UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
                self.emailVTFView.alpha = 1
                self.passwordVTFView.alpha = 1
            }) { (completed) in
                // Present keyboard
                self.emailVTFView.textField.becomeFirstResponder()
            }
        }
        else {
            hideLoginView()
        }
    }
    
    func hideLoginView() {
        if loginMode {

            self.resignFirstResponder()
            
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
                self.emailVTFView.alpha = 0
                self.passwordVTFView.alpha = 0
                
            }) { (completed) in
                self.emailVTFView.textField.text = ""
                self.passwordVTFView.textField.text = ""
                
                self.emailVTFView.hidden = true
                self.passwordVTFView.hidden = true
                
                self.logoImageView.hidden = false
                self.appNameLabel.hidden = false

                self.loginMode = false
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if !emailVTFView.textField.text!.isEmpty {
                self.passwordVTFView.textField.becomeFirstResponder()
            }
        case 1:
            loginUser()
        default:
            break
        }
        return true
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
            self.loginButtonsBottomConstraint.constant = changeInHeight
        }
        else {
            self.loginButtonsBottomConstraint.constant = 0
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
        errorPopoverView.confirmButton.addTarget(self, action: #selector(OnboardingViewController.hidePopoverView(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
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
                self.passwordVTFView.textField.becomeFirstResponder()
        })
    }

}
