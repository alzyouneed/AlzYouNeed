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
    
    @IBOutlet var familyIdValidateTextFieldView: validateTextFieldView!
    @IBOutlet var passwordValidateTextFieldView: validateTextFieldView!
    @IBOutlet var confirmPasswordValidateTextFieldView: validateTextFieldView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        configureView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func createNewFamily() {
        
    }
    
    func configureView() {
        if newFamily {
          confirmPasswordValidateTextFieldView.hidden = false
        }
        else {
            confirmPasswordValidateTextFieldView.hidden = true
        }
        configureTextFieldViews()
    }
    
    func configureTextFieldViews() {
        self.familyIdValidateTextFieldView.familyIdMode()
        self.passwordValidateTextFieldView.passwordMode(false)
        self.confirmPasswordValidateTextFieldView.passwordMode(true)
        
        self.passwordValidateTextFieldView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.confirmPasswordValidateTextFieldView.textField.addTarget(self, action: #selector(FamilySignupViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
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
