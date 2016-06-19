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
    
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var signUpButton: UIButton!
    
    var loginMode = false
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var cancelButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loginButton.layer.cornerRadius = loginButton.frame.size.width * 0.05
        signUpButton.layer.cornerRadius = signUpButton.frame.size.width * 0.05
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated);
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loginUser() {
        if !loginMode {
            showLoginView()
        }
        else {
            if validateLogin() {
                FIRAuth.auth()?.signInWithEmail(emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
                    if error == nil {
                        print("Login successful")
                        self.view.endEditing(true)
                        self.dismissViewControllerAnimated(true, completion: nil)
                    }
                    else {
                        print(error)
                    }
                })
            }
        }
    }
    
    @IBAction func login(sender: UIButton) {
        loginUser()
        
//        UserDefaultsManager.login()
//        self.dismissViewControllerAnimated(true, completion: nil)
        
//        if !loginMode {
//            showLoginView()
//        }
//        else {
//            if validateLogin() {
//                FIRAuth.auth()?.signInWithEmail(emailTextField.text!, password: passwordTextField.text!, completion: { (user, error) in
//                    if error == nil {
//                        print("Login successful")
//                        self.dismissViewControllerAnimated(true, completion: nil)
//                    }
//                    else {
//                        print(error)
//                    }
//                })
//            }
//        }
    }
    
    func validateLogin() -> Bool {
        if emailTextField.text!.isEmpty {
            print("Missing email")
            return false
        }
        if passwordTextField.text!.isEmpty {
            print("Missing password")
            return false
        }
        return true
    }

    @IBAction func cancelLogin(sender: UIButton) {
        hideLoginView()
        self.view.endEditing(true)
    }
    
    func showLoginView() {
        if !loginMode {
            loginMode = true
            
            self.emailTextField.hidden = false
            self.passwordTextField.hidden = false
            self.cancelButton.hidden = false
            self.emailTextField.alpha = 0
            self.passwordTextField.alpha = 0
            self.cancelButton.alpha = 0
            
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
                self.signUpButton.alpha = 0
                
                self.emailTextField.alpha = 1
                self.passwordTextField.alpha = 1
                self.cancelButton.alpha = 1
            }) { (completed) in
                self.signUpButton.hidden = true
                
                // Present keyboard
                self.emailTextField.becomeFirstResponder()
            }
        }
        else {
            hideLoginView()
        }
    }
    
    func hideLoginView() {
        if loginMode {
            
            self.signUpButton.hidden = false
            
            self.resignFirstResponder()
            
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
                self.signUpButton.alpha = 1
                
                self.emailTextField.alpha = 0
                self.passwordTextField.alpha = 0
                self.cancelButton.alpha = 0
                
            }) { (completed) in
                self.emailTextField.hidden = true
                self.passwordTextField.hidden = true
                self.cancelButton.hidden = true
                
                self.loginMode = false
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.tag == 0 {
            self.passwordTextField.becomeFirstResponder()
        }
        else if textField.tag == 1 {
            loginUser()
        }
        return true
    }
    
//    func openApp() {
//        func showLoginView() {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let onboardingVC: UITabBarController = storyboard.instantiateViewControllerWithIdentifier("tabBarController") as! UITabBarController
//            self.window?.makeKeyAndVisible()
//            self.window?.rootViewController?.presentViewController(onboardingVC, animated: true, completion: nil)
//        }
//    }
}
