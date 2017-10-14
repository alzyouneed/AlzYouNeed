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
import Crashlytics
import FirebaseDatabase

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


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
        
        PKHUD.sharedHUD.dimsBackground = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.presentTransparentNavBar()
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(CreateUserViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(CreateUserViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.emailVTFView.textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override var prefersStatusBarHidden : Bool {
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
        
        self.emailVTFView.textField.addTarget(self, action: #selector(CreateUserViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.passwordVTFView.textField.addTarget(self, action: #selector(CreateUserViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.confirmPasswordVTFView.textField.addTarget(self, action: #selector(CreateUserViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

        nextButtonEnabled()
    }
    
    @IBAction func presentNextView(_ sender: UIButton) {
        signUpUser()
    }
    
    @IBAction func cancelOnboarding(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
   
    
    func textFieldDidChange(_ textField: UITextField) {
        let tag = textField.superview!.superview!.tag
        
        switch tag {
        // Email textField
        case 0:
            _ = validateEmail()
        // Password textField
        case 1:
            _ = validatePassword()
        // Confirm password textField
        case 2:
            _ = validateConfirmPassword()
        default:
            break
        }
        
        nextButtonEnabled()
    }
    
    func nextButtonEnabled() {
        if validFields() {
            nextButton.isEnabled = true
            nextButton.alpha = 1
        }
        else {
            nextButton.isEnabled = false
            nextButton.alpha = 0.5
        }
    }
    
    func nextButtonEnabled(_ enabled: Bool) {
        if enabled {
            nextButton.isEnabled = true
            nextButton.alpha = 1
        }
        else {
            nextButton.isEnabled = false
            nextButton.alpha = 0.5
        }
    }
    //HERE TODO
    // MARK: - Firebase
    func signUpUser() {
        if validFields() {
            
            // Disable interface to avoid extra interaction
            interfaceEnabled(false)
            
            // Show progress view
            HUD.show(.progress)
            
            AYNModel.sharedInstance.onboarding = true
            
            FirebaseManager.createNewUserWithEmail(emailVTFView.textField.text!, password: passwordVTFView.textField.text!, completionHandler: { (user, error) in
                if error != nil {
                    // Sign up failed -- show popoverView with reason
                    Answers.logSignUp(withMethod: "Email",
                                                success: false,
                                                customAttributes: [:])
                    HUD.hide({ (success) in
                        self.showPopoverView(error!)
                        self.interfaceEnabled(true)
                    })
                    
                    // save unsuccessful logins
                    var ref: FIRDatabaseReference!
                    ref = FIRDatabase.database().reference().child("unsuccessful")
                    let key = ref.childByAutoId().key
                    
                    let attempt = ["id":key,
                                     "email":self.emailVTFView.textField.text! as String
                                     ]
                    ref.child(key).setValue(attempt)
                    
                }
                else {
                    // Successfully signed up
                    if user != nil {
                        
//                        let updates = ["email": self.emailVTFView.textField.text!, "completedSignup": "updateUser"]
                        
                        let updates = ["email": self.emailVTFView.textField.text!, "completedSignup": "false"]
                        
                        FirebaseManager.updateUser(updates as NSDictionary, completionHandler: { (error) in
                            if error == nil {
                                Answers.logSignUp(withMethod: "Email",
                                                  success: true,
                                                  customAttributes: [:])
                                
                                // success -- Show progress view success
                                HUD.flash(.success, delay: 0, completion: { (success) in
                                    self.view.endEditing(true)
                                    self.userSignedUp = true
                                    AYNModel.sharedInstance.wasReset = true
                                    self.performSegue(withIdentifier: "updateUser", sender: self)
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
            emailVTFView.isValid(false)
            return false
        }
        else {
            // Check valid
            let userEmailAddress = emailVTFView.textField.text
            let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            let valid = NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: userEmailAddress)
            
            // For debugging
            if valid {
                emailVTFView.isValid(true)
                return true
            }
            else {
                emailVTFView.isValid(false)
                return false
            }
        }
    }
    
    func validatePassword() -> Bool {
        if passwordVTFView.textField.text!.isEmpty {
            passwordVTFView.isValid(false)
            return false
        }
        
        if passwordVTFView.textField.text?.characters.count < 6 {
            passwordVTFView.isValid(false)
            return false
        }
        
        passwordVTFView.isValid(true)
        return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPasswordVTFView.textField.text!.isEmpty {
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
            confirmPasswordVTFView.isValid(false)
            return false
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "updateUser" {
            return userSignedUp
        }
        return false
    }
    
    // MARK: - Keyboard
    func adjustingKeyboardHeight(_ show: Bool, notification: Notification) {
        let userInfo = (notification as NSNotification).userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue 
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
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
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }
    
    func keyboardWillShow(_ sender: Notification) {
        adjustingKeyboardHeight(true, notification: sender)
    }
    
    func keyboardWillHide(_ sender: Notification) {
        adjustingKeyboardHeight(false, notification: sender)
    }
    
    // MARK: - Popover View
    func showPopoverView(_ error: NSError) {
        // Hide keyboard
        self.view.endEditing(true)
        
        // Configure view size
        errorPopoverView = popoverView(frame: CGRect(x: self.view.frame.width/2 - 100, y: self.view.frame.height/2 - 200, width: 200, height: 200))
        // Add popover message
        errorPopoverView.configureWithError(error)
        // Add target to hide view
        errorPopoverView.confirmButton.addTarget(self, action: #selector(CreateUserViewController.hidePopoverView(_:)), for: UIControlEvents.touchUpInside)
        
        // Configure shadow view
        shadowView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        shadowView.backgroundColor = UIColor.black
        
        self.view.addSubview(shadowView)
        self.view.addSubview(errorPopoverView)
        
        errorPopoverView.isHidden = false
        errorPopoverView.alpha = 0
        
        shadowView.isHidden = false
        shadowView.alpha = 0
        
        UIView.animate(withDuration: 0.35, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.errorPopoverView.alpha = 1
            self.shadowView.alpha = 0.2
            }, completion: { (completed) in
        })
    }
    
    func hidePopoverView(_ sender: UIButton) {
        UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
            self.errorPopoverView.alpha = 0
            self.shadowView.alpha = 0
            }, completion: { (completed) in
                self.errorPopoverView.isHidden = true
                self.shadowView.isHidden = true
                
                self.errorPopoverView.removeFromSuperview()
                self.shadowView.removeFromSuperview()
                
                // Show keyboard again
                self.confirmPasswordVTFView.textField.becomeFirstResponder()
        })
    }

    // MARK: - Interface Enable / Disable
    func interfaceEnabled(_ enabled: Bool) {
        nextButtonEnabled(enabled)
        self.navigationController?.navigationItem.backBarButtonItem?.isEnabled = enabled
        emailVTFView.textField.isUserInteractionEnabled = enabled
        passwordVTFView.textField.isUserInteractionEnabled = enabled
        confirmPasswordVTFView.isUserInteractionEnabled = enabled
    }
}
