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
    
    @IBOutlet var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        signUpButton.layer.cornerRadius = signUpButton.frame.size.width * 0.05
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        configureView()
//        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
//        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationController?.navigationBar.translucent = true
    }
    
    override func viewDidAppear(animated: Bool) {
        // Present keyboard
        self.emailTextField.becomeFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // Switch between textFields by using return key
        switch textField.tag {
        case 0:
            if !emailTextField.text!.isEmpty {
                passwordTextField.becomeFirstResponder()
            }
        case 1:
            if !passwordTextField.text!.isEmpty {
                confirmPasswordTextField.becomeFirstResponder()
            }
        default:
            break
        }
        return true
    }
    

    @IBAction func signUp(sender: UIButton) {
        if validateEmail() && validatePassword() {
            FIRAuth.auth()?.createUserWithEmail(emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
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
    
    // MARK: - Configure View
    func configureView() {
        // Setup navigation bar -- make transparent
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
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
