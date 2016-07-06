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
    
    var loginMode = false
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    @IBOutlet var loginButtons: loginButtonsView!
    @IBOutlet var loginButtonsBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OnboardingViewController.keyboardWillShow(_:)), name:UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OnboardingViewController.keyboardWillHide(_:)), name:UIKeyboardWillHideNotification, object: nil)

        configureView()
    }
    
    func configureView() {
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        loginButtons.leftButton.addTarget(self, action: #selector(OnboardingViewController.leftButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        loginButtons.rightButton.addTarget(self, action: #selector(OnboardingViewController.rightButtonAction(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated);
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        loginButtons.resetState()
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
    
    func leftButtonAction(sender: UIButton) {
        switch sender.currentTitle! {
        case "Sign up":
            signUp()
        case "Login":
            loginUser()
        default:
            break
        }
    }
    
    func rightButtonAction(sender: UIButton) {
        switch sender.currentTitle! {
        case "Cancel":
//            print("log in user")
            loginUser()
        case "Login":
            hideLoginView()
            self.view.endEditing(true)
        default:
            break
        }
        
    }
    
    func signUp() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let createUserVC: CreateUserViewController = storyboard.instantiateViewControllerWithIdentifier("createUserVC") as! CreateUserViewController
        self.navigationController?.pushViewController(createUserVC, animated: true)
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
    
    func showLoginView() {
        if !loginMode {
            loginMode = true
            
            self.emailTextField.hidden = false
            self.passwordTextField.hidden = false
            self.emailTextField.alpha = 0
            self.passwordTextField.alpha = 0
            
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
                self.emailTextField.alpha = 1
                self.passwordTextField.alpha = 1
            }) { (completed) in
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

            self.resignFirstResponder()
            
            UIView.animateWithDuration(0.2, delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
                self.emailTextField.alpha = 0
                self.passwordTextField.alpha = 0
            }) { (completed) in
                self.emailTextField.text = ""
                self.passwordTextField.text = ""
                
                self.emailTextField.hidden = true
                self.passwordTextField.hidden = true

                self.loginMode = false
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField.tag {
        case 0:
            if !emailTextField.text!.isEmpty {
                self.passwordTextField.becomeFirstResponder()
            }
        case 1:
            loginUser()
        default:
            break
        }
        return true
    }
    
    // MARK: - Keyboard
    func keyboardWillShow(sender: NSNotification) {
        let info = sender.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.2) {
            self.loginButtonsBottomConstraint.constant = keyboardFrame.size.height
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        UIView.animateWithDuration(0.2) {
            self.loginButtonsBottomConstraint.constant = 0
        }
    }

}
