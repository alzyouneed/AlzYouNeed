//
//  FamilySignupViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/23/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase
import PKHUD

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
        
        // Set tutorial preferences
        UserDefaultsManager.resetUserTutorials()
        PKHUD.sharedHUD.dimsBackground = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.presentTransparentNavBar()
        
        // Add observers
        NotificationCenter.default.addObserver(self, selector: #selector(FamilySignupViewController.keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(FamilySignupViewController.keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        familyIdVTFView.textField.becomeFirstResponder()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 0.5, animations: {
            self.progressView.setProgress(1, animated: true)
        }) 

        // Animate status bar hidden
        UIView.animate(withDuration: 0.2, animations: { 
            self.setNeedsStatusBarAppearanceUpdate()
        }) 
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Remove observers
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    // MARK: - Firebase
    func createNewFamily(_ familyId: String, password: String) {
        // Disable interface to avoid extra interaction
        interfaceEnabled(false)
        
        // Show progress view
        HUD.show(.progress)
        
        FirebaseManager.createNewFamilyGroup(familyId, password: password) { (error, newDatabaseRef) in
            if error != nil {
                // Error creating new family
                HUD.hide({ (success) in
                    self.showPopoverView(error!)
                    self.interfaceEnabled(true)
                })
            }
            else {
                // Successfully created new family
                HUD.flash(.success, delay: 0.2, completion: { (success) in
                    self.view.endEditing(true)
                    AYNModel.sharedInstance.onboarding = false
                    
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabBarController: UITabBarController = storyboard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
                    tabBarController.selectedIndex = 1
                    self.present(tabBarController, animated: true, completion: nil)
                
//                    self.dismissViewControllerAnimated(true, completion: nil)
                })
            }
        }
    }
    
    func joinFamily(_ familyId: String, password: String) {
        // Disable interface to avoid extra interaction
        interfaceEnabled(false)
        
        // Show progress view
        HUD.show(.progress)
        
        FirebaseManager.joinFamilyGroup(familyId, password: password) { (error, newDatabaseRef) in
            if error != nil {
                // Error joining family
                HUD.hide({ (success) in
                    self.showPopoverView(error!)
                    self.interfaceEnabled(true)
                })
            }
            else {
                // Successfully joined family
                HUD.flash(.success, delay: 0, completion: { (success) in
                    self.view.endEditing(true)
                    AYNModel.sharedInstance.onboarding = false
                
                    let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                    let tabBarController: UITabBarController = storyboard.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
                    tabBarController.selectedIndex = 1
                    self.present(tabBarController, animated: true, completion: nil)
                    
//                    self.dismissViewControllerAnimated(true, completion: nil)
                 })
            }
        }
    }
    
    @IBAction func createOrJoinFamily(_ sender: UIButton) {
        
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
        
        self.familyIdVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.passwordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)
        self.confirmPasswordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), for: UIControlEvents.editingChanged)

    }
    
    func configureButton() {
        if newFamily {
            confirmPasswordVTFView.isHidden = false
            // set button title
            createJoinFamilyButton.setTitle("Create Family", for: UIControlState())
            passwordVTFView.textField.returnKeyType = UIReturnKeyType.next
            
            navigationItem.title = "New Family"
        }
        else {
            confirmPasswordVTFView.isHidden = true
            // set button title
            createJoinFamilyButton.setTitle("Join Family", for: UIControlState())
            passwordVTFView.textField.returnKeyType = UIReturnKeyType.done
            
            navigationItem.title = "Existing Family"
        }
    }
    
    func createJoinFamilyButtonEnabled() {
        if validFields() {
            createJoinFamilyButton.isEnabled = true
            createJoinFamilyButton.alpha = 1
        }
        else {
            createJoinFamilyButton.isEnabled = false
            createJoinFamilyButton.alpha = 0.5
        }
    }
    
    func createJoinFamilyButtonEnabled(_ enabled: Bool) {
        if enabled {
            createJoinFamilyButton.isEnabled = true
            createJoinFamilyButton.alpha = 1
        }
        else {
            createJoinFamilyButton.isEnabled = false
            createJoinFamilyButton.alpha = 0.5
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
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
                    joinFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
                }
            }
        case 2:
            if validateConfirmPassword() {
                self.view.endEditing(true)
                // create family
                createNewFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
            }
        default:
            break
        }
        return true
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        if newFamily {
            let tag = textField.superview!.superview!.tag
            switch tag {
            // FamilyId textField
            case 0:
                _ = validateFamilyId()
            // Password textField
            case 1:
                _ = validatePassword()
            // Confirm password textField
            case 2:
                _ = validateConfirmPassword()
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
            self.familyIdVTFView.layoutIfNeeded()
            self.passwordVTFView.layoutIfNeeded()
            self.confirmPasswordVTFView.layoutIfNeeded()
        })
        
        if show {
            self.familyButtonBottomConstraint.constant = changeInHeight
        }
        else {
            self.familyButtonBottomConstraint.constant = 0
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
        errorPopoverView.confirmButton.addTarget(self, action: #selector(FamilySignupViewController.hidePopoverView(_:)), for: UIControlEvents.touchUpInside)
        
        // Configure shadow view
        shadowView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        shadowView.backgroundColor = UIColor.black
        
        self.view.addSubview(shadowView)
        self.view.addSubview(errorPopoverView)
        
        errorPopoverView.isHidden = false
        errorPopoverView.alpha = 0
        
        shadowView.isHidden = false
        shadowView.alpha = 0
        
        DispatchQueue.main.async { 
            UIView.animate(withDuration: 0.35, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.errorPopoverView.alpha = 1
                self.shadowView.alpha = 0.2
                }, completion: { (completed) in
            })
        }
    }
    
    func hidePopoverView(_ sender: UIButton) {
        DispatchQueue.main.async { 
            UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.errorPopoverView.alpha = 0
                self.shadowView.alpha = 0
                }, completion: { (completed) in
                    self.errorPopoverView.isHidden = true
                    self.shadowView.isHidden = true
                    
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
    
    // MARK: - Interface Enable / Disable
    func interfaceEnabled(_ enabled: Bool) {
        createJoinFamilyButtonEnabled(enabled)
        familyIdVTFView.textField.isUserInteractionEnabled = enabled
        passwordVTFView.textField.isUserInteractionEnabled = enabled
        confirmPasswordVTFView.isUserInteractionEnabled = enabled
    }
}
