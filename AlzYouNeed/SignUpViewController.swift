//
//  SignUpViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/17/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var confirmPasswordTextField: UITextField!
    
    @IBOutlet var emailValidateTextFieldView: validateTextFieldView!
    @IBOutlet var passwordValidateTextFieldView: validateTextFieldView!
    @IBOutlet var confirmPasswordValidateTextFieldView: validateTextFieldView!
    
    
    @IBOutlet var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        signUpButton.layer.cornerRadius = signUpButton.frame.size.width * 0.05
        
        emailValidateTextFieldView.textField.delegate = self
        passwordValidateTextFieldView.textField.delegate = self
        confirmPasswordValidateTextFieldView.textField.delegate = self
        
        configureView()
    }
    
    override func viewDidAppear(animated: Bool) {
        // Present keyboard
        self.emailValidateTextFieldView.textField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        let tag = textField.superview!.superview!.tag
        switch tag {
        case 0:
            if !emailValidateTextFieldView.textField.text!.isEmpty {
                passwordValidateTextFieldView.textField.becomeFirstResponder()
            }
        case 1:
            if !passwordValidateTextFieldView.textField.text!.isEmpty {
                confirmPasswordValidateTextFieldView.textField.becomeFirstResponder()
            }
        case 2:
            if !confirmPasswordValidateTextFieldView.textField.text!.isEmpty {
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
    }
    

    @IBAction func signUp(sender: UIButton) {
        signUpUser()
    }
    
    func signUpUser() {
        if validateEmail() && validatePassword() {
            FIRAuth.auth()?.createUserWithEmail(emailValidateTextFieldView.textField.text!, password: passwordValidateTextFieldView.textField.text!, completion: { (user, error) in
                if error == nil {
                    print("Sign up successful")
                    self.view.endEditing(true)
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                else {
                    print(error)
                }
            })
            
        }
    }
    
    // MARK: - Validation
    
    func validateEmail() -> Bool {
        // Check empty
        if emailValidateTextFieldView.textField.text!.isEmpty {
            print("Email field empty")
            emailValidateTextFieldView.isValid(false)
            return false
        }
        else {
            // Check valid
            let userEmailAddress = emailValidateTextFieldView.textField.text
            let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            let emailValid = NSPredicate(format: "SELF MATCHES %@", regex).evaluateWithObject(userEmailAddress)
            
            // For debugging
            if emailValid {
                emailValidateTextFieldView.isValid(true)
                return true
            }
            else {
                print("Email is invalid")
                emailValidateTextFieldView.isValid(false)
                return false
            }
        }
    }
    
    func validatePassword() -> Bool {
        if passwordValidateTextFieldView.textField.text!.isEmpty {
            print("Password field empty")
            passwordValidateTextFieldView.isValid(false)
            return false
        }
        
        if passwordValidateTextFieldView.textField.text?.characters.count < 6 {
            print("Password not long enough")
            passwordValidateTextFieldView.isValid(false)
            return false
        }
        
        passwordValidateTextFieldView.isValid(true)
        return true
    }
    
    func validateConfirmPassword() -> Bool {
        if confirmPasswordValidateTextFieldView.textField.text!.isEmpty {
            print("Confirm password field empty")
            confirmPasswordValidateTextFieldView.isValid(false)
            return false
        }
        
        let passwordText = passwordValidateTextFieldView.textField.text
        let confirmPasswordText = confirmPasswordValidateTextFieldView.textField.text
        let passwordsMatch = passwordText == confirmPasswordText
        
        confirmPasswordValidateTextFieldView.isValid(passwordsMatch)
        
        return passwordsMatch
    }
    
    // MARK: - Configure View
    func configureView() {
        // Setup navigation bar -- make transparent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        
        // Setup validateTextFieldViews
        self.emailValidateTextFieldView.emailMode()
        self.passwordValidateTextFieldView.passwordMode(false)
        self.confirmPasswordValidateTextFieldView.passwordMode(true)
        
        self.emailValidateTextFieldView.textField.addTarget(self, action: #selector(SignUpViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.passwordValidateTextFieldView.textField.addTarget(self, action: #selector(SignUpViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        self.confirmPasswordValidateTextFieldView.textField.addTarget(self, action: #selector(SignUpViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
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
