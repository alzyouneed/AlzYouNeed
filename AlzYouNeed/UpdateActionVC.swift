//
//  UpdateActionVC.swift
//  AlzYouNeed
//
//  Created by Connor Wybranowski on 5/27/17.
//  Copyright © 2017 Alz You Need. All rights reserved.
//

import UIKit
import SkyFloatingLabelTextField
import PKHUD
import Firebase
import FBSDKLoginKit
import GoogleSignIn

class UpdateActionVC: UIViewController {
    
    @IBOutlet var typeLabel: UILabel!
    var type: String!
    
    @IBOutlet var topTextField: SkyFloatingLabelTextField!
    @IBOutlet var bottomTextField: SkyFloatingLabelTextField!
    
    @IBOutlet var updateButton: UIButton!
    @IBOutlet var updateButtonBottomConstraint: NSLayoutConstraint!
    
    // For user reauth
    var emailTextField: UITextField!
    var passwordTextField: UITextField!
    
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
        // Dispose of any resources that can be recreated.
    }
    
    func setupView() {
        setupTypeLabel()
        setupTopTextField()
        setupBottomTextField()
    }
    
    func setupTypeLabel() {
        if type == "changeName" {
            typeLabel.text = "Change Name"
        } else if type == "changePassword" {
            typeLabel.text = "Change Password"
        } else if type == "changePhone" {
            typeLabel.text = "Change Phone Number"
        }
    }
    
    func setupTopTextField() {
        let changeName = (type == "changeName")
        topTextField.font = UIFont(name: "OpenSans", size: 20)
        
        if changeName || type == "changePassword" {
        topTextField.placeholder = changeName ? "First name" : "New password"
        topTextField.title = changeName ? "Name" : "Password"
        topTextField.textColor = UIColor.black
        topTextField.tintColor = UIColor(hex: "7189FF")
        topTextField.lineColor = UIColor.lightGray
        
        topTextField.selectedTitleColor = UIColor(hex: "7189FF")
        topTextField.selectedLineColor = UIColor(hex: "7189FF")
        
//        topTextField.delegate = self
        topTextField.addTarget(self, action:#selector(UpdateActionVC.editedTopTextFieldText), for:UIControlEvents.editingChanged)
        topTextField.autocorrectionType = UITextAutocorrectionType.no
        topTextField.autocapitalizationType = UITextAutocapitalizationType.words
        } else {
            topTextField.placeholder = "Phone number"
            topTextField.title = "Phone number"
            topTextField.textColor = UIColor.black
            topTextField.tintColor = UIColor(hex: "7189FF")
            topTextField.lineColor = UIColor.lightGray
            
            topTextField.selectedTitleColor = UIColor(hex: "7189FF")
            topTextField.selectedLineColor = UIColor(hex: "7189FF")
            
            topTextField.addTarget(self, action:#selector(UpdateActionVC.editedTopTextFieldText), for:UIControlEvents.editingChanged)
            topTextField.keyboardType = UIKeyboardType.phonePad
        }
    }
    
    func setupBottomTextField() {
        let changePassword = (type == "changePassword")
        if changePassword {
            bottomTextField.font = UIFont(name: "OpenSans", size: 20)
            bottomTextField.placeholder = "Confirm password"
            bottomTextField.title = "Confirm password"
            bottomTextField.textColor = UIColor.black
            bottomTextField.tintColor = UIColor(hex: "7189FF")
            bottomTextField.lineColor = UIColor.lightGray
            
            bottomTextField.selectedTitleColor = UIColor(hex: "7189FF")
            bottomTextField.selectedLineColor = UIColor(hex: "7189FF")
            
//            bottomTextField.delegate = self
            bottomTextField.addTarget(self, action:#selector(UpdateActionVC.editedBottomTextFieldText), for:UIControlEvents.editingChanged)
            bottomTextField.autocorrectionType = UITextAutocorrectionType.no
            bottomTextField.autocapitalizationType = UITextAutocapitalizationType.words
        } else {
            bottomTextField.isHidden = true
            bottomTextField.isEnabled = false
        }
    }
    
    func editedTopTextFieldText() {
        validateFields()
    }
    
    func editedBottomTextFieldText() {
        validateFields()
    }
    
    // MARK: - Validation
    func validateFields() {
        if type == "changeName" {
            // Check top not empty
            let topEmpty = (topTextField.text?.isEmpty)!
            enableUpdateButton(enable: !topEmpty)
        } else if type == "changePhone" {
            // Check top not empty
            let topEmpty = (topTextField.text?.isEmpty)!
            let phoneRegex = "^\\d{3}\\d{3}\\d{4}$"
            let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            let valid = phoneTest.evaluate(with: topTextField.text!)
            
            enableUpdateButton(enable: (!topEmpty && valid))
        } else {
            let topEmpty = (topTextField.text?.isEmpty)!
            let bottomEmpty = (bottomTextField.text?.isEmpty)!
            let passwordsMatch = topTextField.text == bottomTextField.text
            enableUpdateButton(enable: (!topEmpty && !bottomEmpty && passwordsMatch))
        }
    }
    
    func enableUpdateButton(enable: Bool) {
        updateButton.isEnabled = enable
        updateButton.alpha = enable ? 1 : 0.6
    }
    
    // MARK: - Adjusting keyboard
    func adjustingKeyboardHeight(show: Bool, notification: NSNotification) {
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as! TimeInterval
        let animationCurveRawNSNumber = userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber
        let animationCurveRaw = animationCurveRawNSNumber.uintValue
        let animationCurve: UIViewAnimationOptions = UIViewAnimationOptions(rawValue: animationCurveRaw)
        let changeInHeight = (keyboardFrame.height) //* (show ? 1 : -1)
        
        UIView.performWithoutAnimation({
            self.topTextField.layoutIfNeeded()
            self.bottomTextField.layoutIfNeeded()
        })
        
        if show {
            // Change constraints here
            updateButtonBottomConstraint.constant = changeInHeight
        } else {
            // Reset constraints here
            updateButtonBottomConstraint.constant = 0
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
    
    // MARK: - Profile Updates
    @IBAction func updateButtonPressed(_ sender: UIButton) {
        if type == "changeName" {
            changeName()
        } else if type == "changePassword" {
            changePassword()
        } else if type == "changePhone" {
            changePhoneNumber()
        }
    }
    
    func changeName() {
        HUD.show(.progress)
        
        let changeRequest = FIRAuth.auth()?.currentUser?.profileChangeRequest()
        changeRequest?.displayName = topTextField.text
        changeRequest?.commitChanges { (error) in
            if let requestError = error {
                print("Error with name Change Request: ", requestError.localizedDescription)
                HUD.flash(.error)
            } else {
                // Save to RTDB
                FirebaseManager.updateUser(updates: ["name" : self.topTextField.text!] as NSDictionary, completionHandler: { (error) in
                    if let error = error {
                        HUD.hide()
                        print("Error updating user: ", error.localizedDescription)
                    } else {
                        print("Updated name")
                        HUD.flash(.success, delay: 0, completion: { (complete) in
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                })
            }
        }
    }
    
    func changePassword() {
        HUD.show(.progress)
        
        FIRAuth.auth()?.currentUser?.updatePassword(bottomTextField.text!, completion: { (error) in
            if let error = error {
                HUD.hide()
                print("Error updating password: ", error.localizedDescription)
                let errorCode = FIRAuthErrorCode(rawValue: error._code)!
                if errorCode == FIRAuthErrorCode.errorCodeInvalidUserToken || errorCode == FIRAuthErrorCode.errorCodeRequiresRecentLogin {
                    self.showReAuthOptions()
                }
            } else {
                print("Updated password")
                HUD.flash(.success, delay: 0, completion: { (complete) in
                    self.navigationController?.popViewController(animated: true)
                })
            }
        })
    }
    
    func changePhoneNumber() {
        HUD.show(.progress)
        
        FirebaseManager.updateUser(updates: ["phoneNumber" : self.topTextField.text!] as NSDictionary, completionHandler: { (error) in
            if let error = error {
                HUD.hide()
                print("Error updating user: ", error.localizedDescription)
            } else {
                print("Updated phone number")
                HUD.flash(.success, delay: 0, completion: { (complete) in
                    self.navigationController?.popViewController(animated: true)
                })
            }
        })
    }
    
    func showReAuthOptions() {
        let authOptions = UIAlertController(title: "Sign in to Continue", message: "Select your sign-in method to complete this action", preferredStyle: .actionSheet)
        
        let facebookOption = UIAlertAction(title: "Facebook", style: .default) { (action) in
            self.reAuthUser(provider: "Facebook", email: nil, password: nil)
        }
        let googleOption = UIAlertAction(title: "Google", style: .default) { (action) in
            self.reAuthUser(provider: "Google", email: nil, password: nil)
        }
        let emailOption = UIAlertAction(title: "Email", style: .default) { (action) in
            self.showEmailLogin()
        }
        let cancelOption = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        authOptions.addAction(facebookOption)
        authOptions.addAction(googleOption)
        authOptions.addAction(emailOption)
        authOptions.addAction(cancelOption)
        
        self.present(authOptions, animated: true, completion: nil)
    }
    
    func showEmailLogin() {
        let emailAlert = UIAlertController(title: "Email Sign-in", message: "Login using your Email and Password to continue", preferredStyle: .alert)
        
        emailAlert.addTextField { (textField) in
            textField.placeholder = "Email address"
            textField.keyboardType = UIKeyboardType.emailAddress
            self.emailTextField = textField
        }
        emailAlert.addTextField { (textField) in
            textField.placeholder = "Password"
            self.passwordTextField = textField
        }
        
        let loginAction = UIAlertAction(title: "Sign in", style: .default) { (action) in
            if let email = self.emailTextField.text, let password = self.passwordTextField.text {
                self.reAuthUser(provider: "Email", email: email, password: password)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        emailAlert.addAction(loginAction)
        emailAlert.addAction(cancelAction)
        
        self.present(emailAlert, animated: true, completion: nil)
    }
    
    func reAuthUser(provider: String, email: String?, password: String?) {
        let user = FIRAuth.auth()?.currentUser
        var credential: FIRAuthCredential? = nil
        
        if provider == "Facebook" {
            credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
        } else if provider == "Google" {
            if let authentication = GIDSignIn.sharedInstance().currentUser.authentication {
                credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
            }
        } else if provider == "Email" {
            if let email = email, let password = password {
                credential = FIREmailPasswordAuthProvider.credential(withEmail: email, password: password)
            }
        }
        
        if credential != nil {
            // Prompt the user to re-provide their sign-in credentials
            user?.reauthenticate(with: credential!) { error in
                if let error = error {
                    print("Error reauthenticating user: ", error.localizedDescription)
                    HUD.flash(.error)
                } else {
                    print("Reauthenticated user")
                    HUD.flash(.label("Signed in"), delay: 0, completion: { (complete) in
                        // User re-authenticated.
                        self.changePassword()
                    })
                }
            }
        }
    }
    
}
