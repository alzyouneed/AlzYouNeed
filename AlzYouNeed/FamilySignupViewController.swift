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
    
    // MARK: - UI Elements
    
    @IBOutlet var familyIdVTFView: validateTextFieldView!
    @IBOutlet var passwordVTFView: validateTextFieldView!
    @IBOutlet var confirmPasswordVTFView: validateTextFieldView!
    @IBOutlet var createJoinFamilyButton: UIButton!
    
    // MARK: - Constraints
    @IBOutlet var createJoinFamilyButtonTopLayoutConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        familyIdVTFView.textField.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Firebase
    func createNewFamily(familyId: String, password: String) {
        FirebaseManager.createNewFamilyGroup(familyId, password: password) { (error, newDatabaseRef) in
            if error != nil {
                // Error creating new family
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
            
            // Set layout constraint
            createJoinFamilyButtonTopLayoutConstraint.constant = 8
        }
        else {
            confirmPasswordVTFView.hidden = true
            // set button title
            createJoinFamilyButton.setTitle("Join Family", forState: UIControlState.Normal)
            passwordVTFView.textField.returnKeyType = UIReturnKeyType.Done
            
            // Set layout constraint
            createJoinFamilyButtonTopLayoutConstraint.constant -= confirmPasswordVTFView.frame.height + 8
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
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
