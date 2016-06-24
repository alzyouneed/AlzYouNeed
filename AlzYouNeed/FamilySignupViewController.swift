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

        // Do any additional setup after loading the view.
        
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Firebase
    func createNewFamily() {
        if newFamily {
            if let user = FIRAuth.auth()?.currentUser {
                print("Saving new family to realtime DB")
                
                let databaseRef = FIRDatabase.database().reference()
                
//                let userToSave = ["name": nameVTFView.textField.text!, "email": "\(user.email!)", "phoneNumber": phoneNumberVTFView.textField.text!, "familyID": "", "patient": "false", "completedSignup": "false"]
                
//                databaseRef.child("users/\(user.uid)").setValue(userToSave)
            }
            
            
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
        
        self.passwordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.confirmPasswordVTFView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
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
