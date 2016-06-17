//
//  SignUpViewController.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 6/17/16.
//  Copyright © 2016 Alz You Need. All rights reserved.
//

import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var confirmPasswordTextField: UITextField!
    
    @IBOutlet var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        signUpButton.layer.cornerRadius = signUpButton.frame.size.width * 0.05
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    

    @IBAction func signUp(sender: UIButton) {
        if validateEmail() && validatePassword() {
            FIRAuth.auth()?.createUserWithEmail(emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
                if error == nil {
                    print("Sign up successful")
                    UserDefaultsManager.login()
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
                else {
                    print(error)
                }
            })
            
        }
    }
    
    func validateEmail() -> Bool {
        // Check empty
        if emailTextField.text!.isEmpty {
            print("Email field empty")
            return false
        }
        else {
            // Check valid
            let userEmailAddress = emailTextField.text
            let regex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
            let emailValid = NSPredicate(format: "SELF MATCHES %@", regex).evaluateWithObject(userEmailAddress)
            
            // For debugging
            if emailValid {
                return true
            }
            else {
                print("Email is invalid")
                return false
            }
        }
    }
    
    func validatePassword() -> Bool {
        if passwordTextField.text!.isEmpty {
            print("Password field empty")
            return false
        }
        if confirmPasswordTextField.text!.isEmpty {
            print("Confirm password field empty")
            return false
        }
        
        if passwordTextField.text?.characters.count < 6 {
            print("Password not long enough")
            return false
        }
        
        let passwordText = passwordTextField.text
        let confirmPasswordText = confirmPasswordTextField.text
        let passwordsMatch = passwordText == confirmPasswordText
        
        // For debugging
        if passwordsMatch {
            return true
        }
        else {
            print("Passwords don't match")
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
