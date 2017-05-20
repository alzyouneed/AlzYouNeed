//
//  EmailVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/19/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField

class EmailVC: UIViewController, UITextFieldDelegate {

    @IBOutlet var emailTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet var passwordTextField: SkyFloatingLabelTextFieldWithIcon!
    @IBOutlet var signUpButton: UIButton!
    @IBOutlet var signUpButtonBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(EmailVC.keyboardWillShow(sender:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EmailVC.keyboardWillHide(sender:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        validateFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupView() {
        setupEmailTextField()
        setupPasswordTextField()
        
        self.navigationController?.navigationBar.barTintColor = UIColor(hex: "495060")
    }
    
    func setupEmailTextField() {
        emailTextField.font = UIFont(name: "OpenSans", size: 20)
        emailTextField.placeholder = "Email address"
        emailTextField.title = "Email"
        emailTextField.textColor = UIColor.black
        emailTextField.tintColor = UIColor(hex: "7d80da")
        emailTextField.lineColor = UIColor.lightGray
        emailTextField.iconFont = UIFont(name: "FontAwesome", size: 14)
        emailTextField.iconText = String.fontAwesomeIcon(name: .envelope)
        emailTextField.iconMarginBottom = -3
        emailTextField.selectedIconColor = UIColor(hex: "7d80da")
        
        emailTextField.selectedTitleColor = UIColor(hex: "7d80da")
        emailTextField.selectedLineColor = UIColor(hex: "7d80da")
        
        emailTextField.errorColor = UIColor(hex: "EF3054")
        emailTextField.delegate = self
        emailTextField.addTarget(self, action:#selector(EmailVC.editedEmailText), for:UIControlEvents.editingChanged)
        
        emailTextField.keyboardType = UIKeyboardType.emailAddress
        emailTextField.autocorrectionType = UITextAutocorrectionType.no
    }
    
    func setupPasswordTextField() {
        passwordTextField.font = UIFont(name: "OpenSans", size: 20)
        passwordTextField.placeholder = "Password"
        passwordTextField.title = "Password"
        passwordTextField.textColor = UIColor.black
        passwordTextField.tintColor = UIColor(hex: "7d80da")
        passwordTextField.lineColor = UIColor.lightGray
        passwordTextField.iconFont = UIFont(name: "FontAwesome", size: 14)
        passwordTextField.iconText = String.fontAwesomeIcon(name: .key)
        passwordTextField.iconMarginBottom = -3
        passwordTextField.selectedIconColor = UIColor(hex: "7d80da")
        
        passwordTextField.selectedTitleColor = UIColor(hex: "7d80da")
        passwordTextField.selectedLineColor = UIColor(hex: "7d80da")
        
        passwordTextField.delegate = self
        passwordTextField.addTarget(self, action:#selector(EmailVC.editedPasswordText), for:UIControlEvents.editingChanged)
        passwordTextField.autocorrectionType = UITextAutocorrectionType.no
    }
    
    // MARK: -- Adjusting keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
        UIView.performWithoutAnimation({
            self.emailTextField.layoutIfNeeded()
            self.passwordTextField.layoutIfNeeded()
        })
        
        if show {
            // Change constraints here
            signUpButtonBottomConstraint.constant = changeInHeight
        } else {
            // Reset constraints here
            signUpButtonBottomConstraint.constant = 0
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, options: animationCurve, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    func keyboardWillShow(sender: NSNotification) {
        adjustingKeyboardHeight(show: true, notification: sender)
    }
    
    func keyboardWillHide(sender: NSNotification) {
        adjustingKeyboardHeight(show: false, notification: sender)
    }
    
    // MARK: -- TextField changes
    func editedEmailText() {
        if let text = emailTextField.text {
            if ((text.characters.count < 3  && text.characters.count > 0) || (!text.contains("@") && text.characters.count > 0)) {
                self.emailTextField.errorMessage = "Invalid email"
            } else {
                self.emailTextField.errorMessage = ""
            }
        }
        validateFields()
    }
    
    func editedPasswordText() {
        validateFields()
    }
    
    // MARK: -- Validation
    func validateFields() {
        if !emailTextField.hasErrorMessage && (passwordTextField.text?.characters.count)! >= 6 {
//            print("Ready to signup")
            enableSignup(enable: true)
        } else {
            enableSignup(enable: false)
        }
    }
    
    func enableSignup(enable: Bool) {
        signUpButton.isEnabled = enable
        signUpButton.alpha = enable ? 1 : 0.6
    }
    
    // MARK: -- Sign up
    @IBAction func signUpPressed(_ sender: UIButton) {
        // If Firebase sign-up succeeds then present next VC
        presentNextVC()
    }
    
    func presentNextVC() {
        print("Present familyStepVC")
        // Present next VC
        self.performSegue(withIdentifier: "emailToFamily", sender: self)
    }

}
