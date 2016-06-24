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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureView()
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
        // Create family
        if newFamily {
            createNewFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
        }
        // Join family
        else {
            joinFamily(familyIdVTFView.textField.text!, password: passwordVTFView.textField.text!)
        }
    }
    
    func configureView() {
        if newFamily {
            confirmPasswordVTFView.hidden = false
        }
        else {
            confirmPasswordVTFView.hidden = true
        }
        configureTextFieldViews()
    }
    
    func configureTextFieldViews() {
        self.familyIdVTFView.familyIdMode()
        self.passwordVTFView.passwordMode(false)
        self.confirmPasswordVTFView.passwordMode(true)
        
        //        self.passwordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        //        self.confirmPasswordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        //        let tag = textField.superview!.superview!.tag
        //        switch tag {
        //        case 0:
        //            if !emailValidateTextFieldView.textField.text!.isEmpty {
        //                passwordValidateTextFieldView.textField.becomeFirstResponder()
        //            }
        //        case 1:
        //            if !passwordValidateTextFieldView.textField.text!.isEmpty {
        //                confirmPasswordValidateTextFieldView.textField.becomeFirstResponder()
        //            }
        //        case 2:
        //            if !confirmPasswordValidateTextFieldView.textField.text!.isEmpty {
        //                signUpUser()
        //            }
        //        default:
        //            break
        //        }
        return true
    }
    
    func textFieldDidChange(textField: UITextField) {
        //        let tag = textField.superview!.superview!.tag
        //
        //        switch tag {
        //        // Email textField
        //        case 0:
        //            validateEmail()
        //        // Password textField
        //        case 1:
        //            validatePassword()
        //        // Confirm password textField
        //        case 2:
        //            validateConfirmPassword()
        //        default:
        //            break
        //        }
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
